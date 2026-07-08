//
//  BodyMetricCustomizeSheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

struct BodySettingsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Inject private var userService: UserService

    @Query(sort: \WeightEntry.date, order: .reverse) private var allWeightEntries: [WeightEntry]

    // Units (read-only for calculations; pickers stay in Profile)
    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue

    // Calorie Target
    @AppStorage(ActivityLevel.appStorageKey) private var activityLevelRaw: String = ActivityLevel.sedentary.rawValue

    // Goals
    @AppStorage("weightGoalKg") private var weightGoalKg: Double = 0
    @AppStorage("bodyFatGoalPercentage") private var bodyFatGoalPercentage: Double = 0
    @AppStorage("waistGoalCm") private var waistGoalCm: Double = 0
    @AppStorage("bodyGoalDeadlineRaw") private var bodyGoalDeadlineRaw: Double = 0

    // Metrics
    @AppStorage("bodyMetricOrder") private var orderRaw: String = BodyMetric.defaultOrder
    @AppStorage("bodyMetric_weight_enabled") private var weightEnabled: Bool = true
    @AppStorage("bodyMetric_bodyFat_enabled") private var bodyFatEnabled: Bool = true
    @AppStorage("bodyMetric_bmi_enabled") private var bmiEnabled: Bool = true
    @AppStorage("bodyMetric_waist_enabled") private var waistEnabled: Bool = true

    @State private var metrics: [BodyMetric] = []
    @State private var appliedCalorieGoal: Double? = nil

    // MARK: - Computed

    private var preferredUnit: BodyWeightUnit { BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs }
    private var preferredHeightUnit: HeightUnit { HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn }
    private var preferredWaistUnit: WaistUnit { preferredHeightUnit.waistUnit }
    private var activityLevel: ActivityLevel { ActivityLevel(rawValue: activityLevelRaw) ?? .sedentary }

    private var latestWeight: WeightEntry? { allWeightEntries.first }

    private var hasWeightGoal: Bool { weightGoalKg > 0 }
    private var hasBodyFatGoal: Bool { bodyFatGoalPercentage > 0 }
    private var hasWaistGoal: Bool { waistGoalCm > 0 }

    private var goalDeadline: Date? {
        guard bodyGoalDeadlineRaw > 0 else { return nil }
        return Date(timeIntervalSinceReferenceDate: bodyGoalDeadlineRaw)
    }
    private var hasGoalDeadline: Bool { goalDeadline != nil }

    private var weeksToDeadline: Double? {
        guard let deadline = goalDeadline else { return nil }
        return max(deadline.timeIntervalSince(.now) / (7 * 86400), 0)
    }

    private var ageYears: Int? {
        guard let interval = userService.currentUser.getUserAge() else { return nil }
        return Int(interval / (365.25 * 24 * 3600))
    }

    private var bmr: Double? {
        guard let heightCm = userService.currentUser.heightCm, heightCm > 0,
              let weightKg = latestWeight?.weightKg,
              let age = ageYears else { return nil }
        return BmrCalculator.bmr(
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: age,
            gender: userService.currentUser.gender
        )
    }

    private var tdee: Double? {
        guard let b = bmr else { return nil }
        return BmrCalculator.tdee(bmr: b, activityLevel: activityLevel)
    }

    private var suggestedCalories: Double? {
        guard let t = tdee, let weightKg = latestWeight?.weightKg, hasWeightGoal else { return nil }
        if let weeks = weeksToDeadline, weeks > 0 {
            return BmrCalculator.calorieTarget(tdee: t, currentWeightKg: weightKg, goalWeightKg: weightGoalKg, weeksToDeadline: weeks)
        }
        return BmrCalculator.calorieTarget(tdee: t, currentWeightKg: weightKg, goalWeightKg: weightGoalKg)
    }

    private var tdeeHint: String {
        if userService.currentUser.heightCm == nil { return "Set your height in Profile to calculate TDEE." }
        if latestWeight == nil { return "Log your weight to calculate TDEE." }
        if userService.currentUser.birthdate == nil { return "Set your birthdate in Profile to calculate TDEE." }
        return "Complete your profile to calculate TDEE."
    }

    private var visibleGoalMetrics: [BodyMetric] {
        BodyMetric.ordered(from: orderRaw).filter {
            switch $0 {
            case .weight: return weightEnabled
            case .bodyFat: return bodyFatEnabled
            case .bmi: return false
            case .waist: return waistEnabled
            }
        }
    }

    private func enabledBinding(for metric: BodyMetric) -> Binding<Bool> {
        switch metric {
        case .weight: return $weightEnabled
        case .bodyFat: return $bodyFatEnabled
        case .bmi: return $bmiEnabled
        case .waist: return $waistEnabled
        }
    }

    private func saveCalorieGoal(_ kcal: Double) {
        var updated = userService.currentUser
        updated.calorieGoal = kcal
        Task { try? await userService.save(user: updated) }
        appliedCalorieGoal = kcal
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                CalorieTargetSection()
                GoalsSection()
                MetricsSection()
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Body Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                metrics = BodyMetric.ordered(from: orderRaw)
            }
        }
    }

    // MARK: - Calorie Target

    @ViewBuilder private func CalorieTargetSection() -> some View {
        Section {
            if let bmrValue = bmr, let tdeeValue = tdee {
                let target = suggestedCalories ?? tdeeValue
                let diff = target - tdeeValue

                VStack(alignment: .leading, spacing: 0) {
                    Picker("Activity Level", selection: $activityLevelRaw) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.label).tag(level.rawValue)
                        }
                    }
                    .tint(.accentColor)
                    .onChange(of: activityLevelRaw) { appliedCalorieGoal = nil }

                    Text(activityLevel.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }

                LabeledContent("BMR") {
                    Text("\(bmrValue.formatted(maxDigits: 0)) kcal")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("TDEE") {
                    Text("\(tdeeValue.formatted(maxDigits: 0)) kcal")
                        .bold()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggested Intake")
                        if diff < -50 {
                            Text("\(Int(diff).formatted()) kcal deficit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if diff > 50 {
                            Text("+\(Int(diff).formatted()) kcal surplus")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Maintenance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(target.formatted(maxDigits: 0)) kcal")
                        .bold()
                }

                Button {
                    saveCalorieGoal(target)
                } label: {
                    HStack {
                        Spacer()
                        if let applied = appliedCalorieGoal {
                            Label("Applied \(applied.formatted(maxDigits: 0)) kcal", systemImage: "checkmark")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Apply as Calorie Goal")
                        }
                        Spacer()
                    }
                }
                .disabled(appliedCalorieGoal != nil)

            } else {
                Text(tdeeHint)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Calorie Target")
        } footer: {
            Text("**BMR** (Basal Metabolic Rate) is the calories your body burns at rest. **TDEE** (Total Daily Energy Expenditure) adds your activity level on top of that.")
        }
    }

    // MARK: - Goals

    @ViewBuilder private func GoalsSection() -> some View {
        if !visibleGoalMetrics.isEmpty {
            Section("Goals") {
                PremiumGate(trigger: .weightGoal, feature: "weight_goal") {
                    VStack(spacing: 0) {
                        ForEach(Array(visibleGoalMetrics.enumerated()), id: \.offset) { i, metric in
                            if i > 0 { Divider() }
                            GoalRow(for: metric)
                        }
                        Divider()
                        DeadlineRow()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
        }
    }

    @ViewBuilder private func GoalRow(for metric: BodyMetric) -> some View {
        switch metric {
        case .weight:
            GoalField(
                title: "Weight",
                value: Binding(
                    get: { hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil },
                    set: { weightGoalKg = $0.map { preferredUnit.toKg($0) } ?? 0 }
                ),
                unit: preferredUnit.label
            )
        case .bodyFat:
            GoalField(
                title: "Body Fat",
                value: Binding(
                    get: { hasBodyFatGoal ? bodyFatGoalPercentage : nil },
                    set: { bodyFatGoalPercentage = $0 ?? 0 }
                ),
                unit: "%"
            )
        case .waist:
            GoalField(
                title: "Waist",
                value: Binding(
                    get: { hasWaistGoal ? preferredWaistUnit.fromCm(waistGoalCm) : nil },
                    set: { waistGoalCm = $0.map { preferredWaistUnit.toCm($0) } ?? 0 }
                ),
                unit: preferredWaistUnit.label
            )
        case .bmi:
            EmptyView()
        }
    }

    @ViewBuilder private func GoalField(title: String, value: Binding<Double?>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.light)
            Spacer()
            TextField(
                "Not set",
                text: Binding(
                    get: { value.wrappedValue.map { $0.formatted(maxDigits: 1) } ?? "" },
                    set: { str in
                        if str.isEmpty { value.wrappedValue = nil }
                        else if let d = Double(str) { value.wrappedValue = d }
                    }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: 100)
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder private func DeadlineRow() -> some View {
        HStack {
            Text("By")
                .font(.subheadline)
                .fontWeight(.light)
            Spacer()
            if hasGoalDeadline {
                Button("Clear") { bodyGoalDeadlineRaw = 0 }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {

                } label: {
                    Text((goalDeadline ?? .now).formatted(date: .abbreviated, time: .omitted))
                        .bold()
                        .foregroundStyle(Color.accentColor)
                }
                .overlay {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { goalDeadline ?? .now },
                            set: { bodyGoalDeadlineRaw = $0.timeIntervalSinceReferenceDate }
                        ),
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .blendMode(.destinationOver)
                }
            } else {
                Button("Set deadline") {
                    let threeMonths = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
                    bodyGoalDeadlineRaw = threeMonths.timeIntervalSinceReferenceDate
                }
                .font(.subheadline)
                .bold()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Metrics

    @ViewBuilder private func MetricsSection() -> some View {
        Section {
            ForEach(metrics) { metric in
                HStack {
                    Toggle("", isOn: enabledBinding(for: metric))
                        .labelsHidden()
                    Text(metric.displayName)
                    Spacer()
                }
            }
            .onMove { from, to in
                metrics.move(fromOffsets: from, toOffset: to)
                orderRaw = metrics.map(\.rawValue).joined(separator: ",")
            }
        } header: {
            Text("Metrics")
        } footer: {
            Text("Drag to reorder. Disabled metrics are hidden from the Body tab.")
        }
    }
}

#Preview {
    BodySettingsSheet()
}
