//
//  WeightEntrySheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import SwiftData

struct WeightEntrySheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Inject private var engagementAnalytics: EngagementAnalytics

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @State private var date: Date = .now

    @Query private var weights: [WeightEntry]
    @Query private var bodyFats: [BodyFatEntry]
    @Query private var waists: [WaistEntry]
    @State private var weightText: String = ""
    @State private var bodyFatText: String = ""
    @State private var waistText: String = ""

    let existingWeight: WeightEntry?
    let existingBodyFat: BodyFatEntry?
    let existingWaist: WaistEntry?

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var preferredWaistUnit: WaistUnit {
        (HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn).waistUnit
    }

    init(existingWeight: WeightEntry? = nil, existingBodyFat: BodyFatEntry? = nil, existingWaist: WaistEntry? = nil) {
        self.existingWeight = existingWeight
        self.existingBodyFat = existingBodyFat
        self.existingWaist = existingWaist
    }

    private var hasValidWeight: Bool {
        guard !weightText.isEmpty else { return false }
        guard let w = Double(weightText), w > 0 else { return false }
        return true
    }

    private var hasValidBodyFat: Bool {
        guard !bodyFatText.isEmpty else { return false }
        guard let bf = Double(bodyFatText), bf > 0, bf < 100 else { return false }
        return true
    }

    private var hasValidWaist: Bool {
        guard !waistText.isEmpty else { return false }
        guard let w = Double(waistText), w > 0 else { return false }
        return true
    }

    private var canSave: Bool {
        let hasAtLeastOne = hasValidWeight || hasValidBodyFat || hasValidWaist
        let weightOk = weightText.isEmpty || hasValidWeight
        let bodyFatOk = bodyFatText.isEmpty || hasValidBodyFat
        let waistOk = waistText.isEmpty || hasValidWaist
        return hasAtLeastOne && weightOk && bodyFatOk && waistOk
    }

    private var day: SimpleDate { SimpleDate(date: date) ?? .today }

    private var dayBinding: Binding<SimpleDate> {
        Binding(get: { day }, set: { date = $0.toDate() ?? .now })
    }

    private var previousWeight: (date: SimpleDate, value: Double)? {
        MeasurementChange.previous(before: day, in: weights, date: \.date) { preferredUnit.fromKg($0.weightKg) }
    }

    private var previousBodyFat: (date: SimpleDate, value: Double)? {
        MeasurementChange.previous(before: day, in: bodyFats, date: \.date, value: \.percentage)
    }

    private var previousWaist: (date: SimpleDate, value: Double)? {
        MeasurementChange.previous(before: day, in: waists, date: \.date) { preferredWaistUnit.fromCm($0.circumferenceCm) }
    }

    private var isEditing: Bool { existingWeight != nil || existingBodyFat != nil || existingWaist != nil }

    private var saveButtonTitle: String {
        if !canSave { return "Enter a measurement" }
        return isEditing ? "Save Changes" : "Log Entry"
    }

    /// "182 lb, down 0.4 since Tuesday · Today" (weight first, else body fat, else waist).
    private var saveButtonDetail: String? {
        guard canSave else { return nil }
        let summary: String
        if hasValidWeight, let value = Double(weightText) {
            summary = MeasurementChange.summary(value: value, unit: preferredUnit.label,
                                                previous: previousWeight?.value, previousDay: previousWeight?.date.formatted())
        } else if hasValidBodyFat, let value = Double(bodyFatText) {
            summary = MeasurementChange.summary(value: value, unit: "% body fat",
                                                previous: previousBodyFat?.value, previousDay: previousBodyFat?.date.formatted())
        } else if hasValidWaist, let value = Double(waistText) {
            summary = MeasurementChange.summary(value: value, unit: preferredWaistUnit.label + " waist",
                                                previous: previousWaist?.value, previousDay: previousWaist?.date.formatted())
        } else {
            return nil
        }
        return "\(summary) · \(day.formatted())"
    }

    private func populateFromExisting() {
        if let existing = existingWeight {
            date = existing.date.toDate() ?? .now
            let displayWeight = preferredUnit.fromKg(existing.weightKg)
            weightText = displayWeight.formatted(maxDigits: 1)
        }
        if let existing = existingBodyFat {
            if existingWeight == nil {
                date = existing.date.toDate() ?? .now
            }
            bodyFatText = existing.percentage.formatted(maxDigits: 1)
        }
        if let existing = existingWaist {
            if existingWeight == nil && existingBodyFat == nil {
                date = existing.date.toDate() ?? .now
            }
            waistText = preferredWaistUnit.fromCm(existing.circumferenceCm).formatted(maxDigits: 1)
        }
    }

    private func save() {
        guard let simpleDate = SimpleDate(date: date) else { return }

        if hasValidWeight, let weightValue = Double(weightText) {
            let weightKg = preferredUnit.toKg(weightValue)
            let weightDescriptor = FetchDescriptor<WeightEntry>(
                predicate: #Predicate { $0.date == simpleDate }
            )
            if let existing = try? modelContext.fetch(weightDescriptor).first {
                existing.weightKg = weightKg
            } else {
                modelContext.insert(WeightEntry(date: simpleDate, weightKg: weightKg))
            }
            if healthSyncEnabled {
                Task { await HealthKitManager.shared.saveWeight(weightKg, date: date) }
            }
        }

        if hasValidBodyFat, let bodyFatValue = Double(bodyFatText) {
            let bfDescriptor = FetchDescriptor<BodyFatEntry>(
                predicate: #Predicate { $0.date == simpleDate }
            )
            if let existing = try? modelContext.fetch(bfDescriptor).first {
                existing.percentage = bodyFatValue
            } else {
                modelContext.insert(BodyFatEntry(date: simpleDate, percentage: bodyFatValue))
            }
            if healthSyncEnabled {
                Task { await HealthKitManager.shared.saveBodyFat(bodyFatValue, date: date) }
            }
        }

        if hasValidWaist, let waistValue = Double(waistText) {
            let waistCm = preferredWaistUnit.toCm(waistValue)
            let waistDescriptor = FetchDescriptor<WaistEntry>(
                predicate: #Predicate { $0.date == simpleDate }
            )
            if let existing = try? modelContext.fetch(waistDescriptor).first {
                existing.circumferenceCm = waistCm
            } else {
                modelContext.insert(WaistEntry(date: simpleDate, circumferenceCm: waistCm))
            }
            if healthSyncEnabled {
                Task { await HealthKitManager.shared.saveWaist(waistCm, date: date) }
            }
        }

        try? modelContext.save()
        engagementAnalytics.weightLogged()
        dismiss()
    }

    var body: some View {
        NavigationStack {
            List {
                LogDateField(logDate: dayBinding)
                    .padding(.horizontal, -16)
                    .listRowDefaultModifiers()

                Section {
                    MeasurementRow("Weight", text: $weightText, unit: preferredUnit.label, previous: previousWeight)
                    MeasurementRow("Body Fat", text: $bodyFatText, unit: "%", previous: previousBodyFat)
                    MeasurementRow("Waist", text: $waistText, unit: preferredWaistUnit.label, previous: previousWaist)
                }
            }
            .listDefaultModifiers()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                LogActionButton(title: saveButtonTitle, detail: saveButtonDetail, isEnabled: canSave) { save() }
            }
            .onAppear { populateFromExisting() }
        }
    }

    /// A number field with the last entry under its name, so the likely value is right there.
    @ViewBuilder private func MeasurementRow(
        _ title: String,
        text: Binding<String>,
        unit: String,
        previous: (date: SimpleDate, value: Double)?
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let previous {
                    Text("Last: \(MeasurementChange.withUnit(previous.value, unit)) · \(previous.date.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            TextField(previous.map { $0.value.formatted(maxDigits: 1) } ?? "--", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .bold()
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: 100)
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    WeightEntrySheet()
}
