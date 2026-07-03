//
//  WeightTrackingView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import SwiftData
import Charts

enum WeightTrendPeriod: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case twelveMonths = "12M"

    var months: Int {
        switch self {
        case .oneMonth: return 1
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .twelveMonths: return 12
        }
    }
}

struct WeightTrackingView: View {

    private static let streakMilestones: Set<Int> = [4, 8, 13, 26, 52]

    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var userService: UserService

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue
    @AppStorage("weightGoalKg") private var weightGoalKg: Double = 0
    @AppStorage("bodyFatGoalPercentage") private var bodyFatGoalPercentage: Double = 0
    @AppStorage("waistGoalCm") private var waistGoalCm: Double = 0
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @Query(sort: \WeightEntry.date, order: .reverse) private var allWeightEntries: [WeightEntry]
    @Query(sort: \BodyFatEntry.date, order: .reverse) private var allBodyFatEntries: [BodyFatEntry]
    @Query(sort: \WaistEntry.date, order: .reverse) private var allWaistEntries: [WaistEntry]

    @AppStorage("bodyMeasurementStreakCount") private var streakCount: Int = 0
    @AppStorage("bodyMeasurementStreakWeekStartDate") private var streakWeekStartDateRaw: Int = 0

    @AppStorage("bodyMetricOrder") private var bodyMetricOrderRaw: String = BodyMetric.defaultOrder
    @AppStorage("bodyMetric_weight_enabled") private var weightEnabled: Bool = true
    @AppStorage("bodyMetric_bodyFat_enabled") private var bodyFatEnabled: Bool = true
    @AppStorage("bodyMetric_bmi_enabled") private var bmiEnabled: Bool = true
    @AppStorage("bodyMetric_waist_enabled") private var waistEnabled: Bool = true
    @AppStorage(ActivityLevel.appStorageKey) private var activityLevelRaw: String = ActivityLevel.sedentary.rawValue
    @AppStorage("bodyGoalDeadlineRaw") private var bodyGoalDeadlineRaw: Double = 0

    @State private var period: WeightTrendPeriod = .oneMonth
    @State private var showEntrySheet: Bool = false
    @State private var showStreakStats: Bool = false
    @State private var showCustomizeSheet: Bool = false
    @State private var hasImportedHealthKit: Bool = false
    @State private var appliedCalorieGoal: Double? = nil

    private var streakStartDate: SimpleDate? {
        guard streakCount > 0,
              let weekStart = SimpleDate(rawValue: UInt32(streakWeekStartDateRaw))
        else { return nil }
        return weekStart.adding(days: -((streakCount - 1) * 7))
    }

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var preferredWaistUnit: WaistUnit {
        (HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn).waistUnit
    }

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

    private var requiredWeeklyWeightChangeKg: Double? {
        guard let weeks = weeksToDeadline, weeks > 0,
              let currentKg = latestWeight?.weightKg,
              hasWeightGoal else { return nil }
        return (weightGoalKg - currentKg) / weeks
    }

    private var requiredWeeklyBodyFatChange: Double? {
        guard let weeks = weeksToDeadline, weeks > 0,
              let currentBF = latestBodyFat?.percentage,
              hasBodyFatGoal else { return nil }
        return (bodyFatGoalPercentage - currentBF) / weeks
    }

    private var requiredWeeklyWaistChangeCm: Double? {
        guard let weeks = weeksToDeadline, weeks > 0,
              let currentWaist = latestWaist?.circumferenceCm,
              hasWaistGoal else { return nil }
        return (waistGoalCm - currentWaist) / weeks
    }

    private var goalChartEndDate: Date {
        if let deadline = goalDeadline, deadline > chartEndDate {
            return deadline
        }
        return chartEndDate
    }

    private var activityLevel: ActivityLevel {
        ActivityLevel(rawValue: activityLevelRaw) ?? .sedentary
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
        guard let t = tdee, let weightKg = latestWeight?.weightKg else { return nil }
        if hasWeightGoal {
            if let weeks = weeksToDeadline, weeks > 0 {
                return BmrCalculator.calorieTarget(tdee: t, currentWeightKg: weightKg, goalWeightKg: weightGoalKg, weeksToDeadline: weeks)
            }
            return BmrCalculator.calorieTarget(tdee: t, currentWeightKg: weightKg, goalWeightKg: weightGoalKg)
        }
        return nil
    }

    private var tdeeHint: String {
        if userService.currentUser.heightCm == nil { return "Set your height in Profile to calculate TDEE." }
        if latestWeight == nil { return "Log your weight to calculate TDEE." }
        if userService.currentUser.birthdate == nil { return "Set your birthdate in Profile to calculate TDEE." }
        return "Complete your profile to calculate TDEE."
    }

    private func saveCalorieGoal(_ kcal: Double) {
        var updated = userService.currentUser
        updated.calorieGoal = kcal
        Task { try? await userService.save(user: updated) }
        appliedCalorieGoal = kcal
    }

    private var visibleMetrics: [BodyMetric] {
        BodyMetric.ordered(from: bodyMetricOrderRaw).filter { metric in
            switch metric {
            case .weight: return weightEnabled
            case .bodyFat: return bodyFatEnabled
            case .bmi: return bmiEnabled
            case .waist: return waistEnabled
            }
        }
    }

    private var cutoffDate: SimpleDate {
        SimpleDate.today.adding(months: -period.months)
    }

    private var chartStartDate: Date {
        cutoffDate.toDate() ?? .now
    }

    private var chartEndDate: Date {
        SimpleDate.today.toDate() ?? .now
    }

    private var filteredWeightEntries: [WeightEntry] {
        let cutoff = cutoffDate
        return allWeightEntries.filter { $0.date >= cutoff }
    }

    private var filteredBodyFatEntries: [BodyFatEntry] {
        let cutoff = cutoffDate
        return allBodyFatEntries.filter { $0.date >= cutoff }
    }

    private var filteredWaistEntries: [WaistEntry] {
        let cutoff = cutoffDate
        return allWaistEntries.filter { $0.date >= cutoff }
    }

    private var latestWeight: WeightEntry? { allWeightEntries.first }
    private var previousWeight: WeightEntry? { allWeightEntries.dropFirst().first }
    private var latestBodyFat: BodyFatEntry? { allBodyFatEntries.first }
    private var previousBodyFat: BodyFatEntry? { allBodyFatEntries.dropFirst().first }
    private var latestWaist: WaistEntry? { allWaistEntries.first }
    private var previousWaist: WaistEntry? { allWaistEntries.dropFirst().first }

    private var weightTrend: Double? {
        guard let latest = latestWeight, let previous = previousWeight else { return nil }
        return latest.weightKg - previous.weightKg
    }

    private var bodyFatTrend: Double? {
        guard let latest = latestBodyFat, let previous = previousBodyFat else { return nil }
        return latest.percentage - previous.percentage
    }

    private var waistTrend: Double? {
        guard let latest = latestWaist, let previous = previousWaist else { return nil }
        return latest.circumferenceCm - previous.circumferenceCm
    }

    private var bmi: Double? {
        guard let heightCm = userService.currentUser.heightCm, heightCm > 0,
              let weightKg = latestWeight?.weightKg else { return nil }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    private var weightChartMin: Double {
        let values = filteredWeightEntries.map { preferredUnit.fromKg($0.weightKg) }
        let dataMin = values.min()
        let goalValue = hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil
        let effectiveMin = [dataMin, goalValue].compactMap { $0 }.min()
        if let effectiveMin { return effectiveMin * 0.98 }
        return preferredUnit == .lbs ? 100 : 45
    }

    private var weightChartMax: Double {
        let values = filteredWeightEntries.map { preferredUnit.fromKg($0.weightKg) }
        let dataMax = values.max()
        let goalValue = hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil
        let effectiveMax = [dataMax, goalValue].compactMap { $0 }.max()
        if let effectiveMax { return effectiveMax * 1.02 }
        return preferredUnit == .lbs ? 250 : 115
    }

    private var bodyFatChartMin: Double {
        let values = filteredBodyFatEntries.map(\.percentage)
        let dataMin = values.min()
        let goalValue = hasBodyFatGoal ? bodyFatGoalPercentage : nil
        let effectiveMin = [dataMin, goalValue].compactMap { $0 }.min()
        if let effectiveMin { return max(effectiveMin - 2, 0) }
        return 10
    }

    private var bodyFatChartMax: Double {
        let values = filteredBodyFatEntries.map(\.percentage)
        let dataMax = values.max()
        let goalValue = hasBodyFatGoal ? bodyFatGoalPercentage : nil
        let effectiveMax = [dataMax, goalValue].compactMap { $0 }.max()
        if let effectiveMax { return effectiveMax + 2 }
        return 40
    }

    private var waistChartMin: Double {
        let values = filteredWaistEntries.map { preferredWaistUnit.fromCm($0.circumferenceCm) }
        let dataMin = values.min()
        let goalValue = hasWaistGoal ? preferredWaistUnit.fromCm(waistGoalCm) : nil
        let effectiveMin = [dataMin, goalValue].compactMap { $0 }.min()
        if let effectiveMin { return effectiveMin * 0.97 }
        return preferredWaistUnit == .inches ? 25 : 60
    }

    private var waistChartMax: Double {
        let values = filteredWaistEntries.map { preferredWaistUnit.fromCm($0.circumferenceCm) }
        let dataMax = values.max()
        let goalValue = hasWaistGoal ? preferredWaistUnit.fromCm(waistGoalCm) : nil
        let effectiveMax = [dataMax, goalValue].compactMap { $0 }.max()
        if let effectiveMax { return effectiveMax * 1.03 }
        return preferredWaistUnit == .inches ? 50 : 130
    }

    private var loggedInPastWeek: Bool {
        let sevenDaysAgo = SimpleDate.today.adding(days: -6)
        let hasWeight = allWeightEntries.contains { $0.date >= sevenDaysAgo }
        let hasBodyFat = allBodyFatEntries.contains { $0.date >= sevenDaysAgo }
        let hasWaist = allWaistEntries.contains { $0.date >= sevenDaysAgo }
        return hasWeight || hasBodyFat || hasWaist
    }

    private func updateBodyMeasurementStreak() {
        let store = BodyMeasurementStreakStore()
        let streak = store.load().updated(loggedInPastWeek: loggedInPastWeek)

        streakCount = streak.count
        streakWeekStartDateRaw = streak.weekStartDate.map { Int($0) } ?? 0

        store.save(streak)
    }

    private func importHealthKitData() {
        guard healthSyncEnabled, !hasImportedHealthKit else { return }
        hasImportedHealthKit = true

        Task {
            let _ = await HealthKitManager.shared.requestAuthorization()
            let weightHistory = await HealthKitManager.shared.fetchWeightHistory()
            let bodyFatHistory = await HealthKitManager.shared.fetchBodyFatHistory()
            let waistHistory = await HealthKitManager.shared.fetchWaistHistory()

            await MainActor.run {
                for entry in weightHistory {
                    guard let simpleDate = SimpleDate(date: entry.date) else { continue }
                    let descriptor = FetchDescriptor<WeightEntry>(
                        predicate: #Predicate { $0.date == simpleDate }
                    )
                    if (try? modelContext.fetch(descriptor).first) == nil {
                        modelContext.insert(WeightEntry(date: simpleDate, weightKg: entry.kg))
                    }
                }

                for entry in bodyFatHistory {
                    guard let simpleDate = SimpleDate(date: entry.date) else { continue }
                    let descriptor = FetchDescriptor<BodyFatEntry>(
                        predicate: #Predicate { $0.date == simpleDate }
                    )
                    if (try? modelContext.fetch(descriptor).first) == nil {
                        modelContext.insert(BodyFatEntry(date: simpleDate, percentage: entry.percentage))
                    }
                }

                for entry in waistHistory {
                    guard let simpleDate = SimpleDate(date: entry.date) else { continue }
                    let descriptor = FetchDescriptor<WaistEntry>(
                        predicate: #Predicate { $0.date == simpleDate }
                    )
                    if (try? modelContext.fetch(descriptor).first) == nil {
                        modelContext.insert(WaistEntry(date: simpleDate, circumferenceCm: entry.cm))
                    }
                }

                try? modelContext.save()
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 2 * .spacingDefault) {
                NativeAdListRow(ad: $ad, size: .small)
                StreakCardView(count: streakCount, unit: "Week", milestones: Self.streakMilestones, onTap: { showStreakStats = true })
                CurrentValues()
                let chartMetrics = visibleMetrics.filter(\.hasChart)
                if !chartMetrics.isEmpty {
                    PeriodPicker()
                    ForEach(chartMetrics) { metric in
                        if metric == .weight { WeightChartCard() }
                        else if metric == .bodyFat { BodyFatChartCard() }
                        else if metric == .waist { WaistChartCard() }
                    }
                }
                GoalsCards()
                TdeeCard()
                HistoryLink()
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Body")
        .toolbar { Toolbar() }
        .onAppear { importHealthKitData() }
        .onChange(of: allWeightEntries.count, initial: true) { updateBodyMeasurementStreak() }
        .onChange(of: allBodyFatEntries.count, initial: true) { updateBodyMeasurementStreak() }
        .onChange(of: allWaistEntries.count, initial: true) { updateBodyMeasurementStreak() }
        .sheet(isPresented: $showEntrySheet) {
            WeightEntrySheet()
        }
        .sheet(isPresented: $showCustomizeSheet) {
            BodyMetricCustomizeSheet()
        }
        .sheet(isPresented: $showStreakStats) {
            StreakStatsView(
                title: "Body Measurement",
                count: streakCount,
                unit: "Week",
                longestCount: nil,
                startDate: streakStartDate,
                milestones: Self.streakMilestones
            )
        }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCustomizeSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showEntrySheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Current Values

    @ViewBuilder private func CurrentValues() -> some View {
        if !visibleMetrics.isEmpty {
            if visibleMetrics.count == 1 {
                MetricCard(for: visibleMetrics[0])
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingDefault) {
                    ForEach(visibleMetrics) { metric in
                        MetricCard(for: metric)
                    }
                }
            }
        }
    }

    @ViewBuilder private func MetricCard(for metric: BodyMetric) -> some View {
        switch metric {
        case .weight: CurrentWeightCard()
        case .bodyFat: CurrentBodyFatCard()
        case .bmi: CurrentBMICard()
        case .waist: CurrentWaistCard()
        }
    }

    @ViewBuilder private func CurrentWeightCard() -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("Weight")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            if let latest = latestWeight {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(Color.blue)
                    Text("\(preferredUnit.fromKg(latest.weightKg).formatted(maxDigits: 1))\(preferredUnit.label)")
                        .contentTransition(.numericText())
                }
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                if let trend = weightTrend {
                    TrendIndicator(trend: preferredUnit.fromKg(trend))
                }
            } else {
                Text("--")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.text)
        .padding(.vertical)
        .inCard(backgroundColor: Color.gray)
    }

    @ViewBuilder private func CurrentBodyFatCard() -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("Body Fat")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            if let latest = latestBodyFat {
                HStack(spacing: 4) {
                    Image(systemName: "percent")
                        .foregroundStyle(Color.orange)
                    Text("\(latest.percentage.formatted(maxDigits: 1))%")
                        .contentTransition(.numericText())
                }
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                if let trend = bodyFatTrend {
                    TrendIndicator(trend: trend)
                }
            } else {
                Text("--")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.text)
        .padding(.vertical)
        .inCard(backgroundColor: Color.gray)
    }

    @ViewBuilder private func CurrentBMICard() -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("BMI")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            if let bmi {
                HStack(spacing: 4) {
                    Image(systemName: "figure.arms.open")
                        .foregroundStyle(Color.purple)
                    Text(bmi.formatted(maxDigits: 1))
                        .contentTransition(.numericText())
                }
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
            } else {
                Text("--")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(userService.currentUser.heightCm == nil ? "Set height in profile" : "Log weight to calculate")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(Color.text)
        .padding(.vertical)
        .inCard(backgroundColor: Color.gray)
    }

    @ViewBuilder private func CurrentWaistCard() -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("Waist")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            if let latest = latestWaist {
                HStack(spacing: 4) {
                    Image(systemName: "ruler")
                        .foregroundStyle(Color.green)
                    Text("\(preferredWaistUnit.fromCm(latest.circumferenceCm).formatted(maxDigits: 1))\(preferredWaistUnit.label)")
                        .contentTransition(.numericText())
                }
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                if let trend = waistTrend {
                    TrendIndicator(trend: preferredWaistUnit.fromCm(trend))
                }
            } else {
                Text("--")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(Color.text)
        .padding(.vertical)
        .inCard(backgroundColor: Color.gray)
    }

    @ViewBuilder private func TrendIndicator(trend: Double) -> some View {
        let isUp = trend > 0.05
        let isDown = trend < -0.05
        HStack(spacing: 2) {
            Image(systemName: isUp ? "arrow.up.right" : isDown ? "arrow.down.right" : "arrow.right")
                .font(.caption.bold())
            Text("\(abs(trend).formatted(maxDigits: 1))")
                .font(.caption)
        }
        .foregroundStyle(isUp ? .red : isDown ? .green : .secondary)
    }

    // MARK: - Period Picker

    @ViewBuilder private func PeriodPicker() -> some View {
        Picker("Period", selection: $period) {
            ForEach(WeightTrendPeriod.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Weight Chart

    @ViewBuilder private func WeightChartCard() -> some View {
        VStack(spacing: .spacingDefault) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .listSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let rate = requiredWeeklyWeightChangeKg, let deadline = goalDeadline {
                    let rateDisplay = preferredUnit.fromKg(abs(rate)).formatted(maxDigits: 2)
                    let direction = rate < 0 ? "lose" : "gain"
                    let deadlineLabel = deadline.formatted(date: .abbreviated, time: .omitted)
                    Text("\(direction) \(rateDisplay) \(preferredUnit.label)/wk to reach goal by \(deadlineLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ZStack {
                WeightChart()
                if filteredWeightEntries.isEmpty {
                    Text("No weight data for this period")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func WeightChart() -> some View {
        let entries = filteredWeightEntries.sorted { $0.date < $1.date }
        let chartMin = weightChartMin
        let chartMax = weightChartMax
        let goalValue = hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil
        let isEmpty = entries.isEmpty
        let showTrajectory = hasWeightGoal && hasGoalDeadline && !entries.isEmpty

        Chart {
            ForEach(entries, id: \.date) { entry in
                let value = preferredUnit.fromKg(entry.weightKg)
                PointMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Weight", value)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(30)

                LineMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Weight", value)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    yStart: .value("Baseline", chartMin),
                    yEnd: .value("Weight", value)
                )
                .foregroundStyle(Color.blue.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }

            if showTrajectory, let current = latestWeight, let deadline = goalDeadline {
                let startValue = preferredUnit.fromKg(current.weightKg)
                let endValue = preferredUnit.fromKg(weightGoalKg)
                LineMark(
                    x: .value("Date", current.date.toDate() ?? .now, unit: .day),
                    y: .value("Weight", startValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))

                LineMark(
                    x: .value("Date", deadline, unit: .day),
                    y: .value("Weight", endValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }

            if let goal = goalValue {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.text.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal: \(goal.formatted(maxDigits: 1)) \(preferredUnit.label)")
                            .font(.caption2)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
            }
        }
        .chartYScale(domain: chartMin...chartMax)
        .chartXScale(domain: chartStartDate...goalChartEndDate)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
        .opacity(isEmpty ? 0.3 : 1)
    }

    // MARK: - Body Fat Chart

    @ViewBuilder private func BodyFatChartCard() -> some View {
        VStack(spacing: .spacingDefault) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Body Fat")
                    .listSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let rate = requiredWeeklyBodyFatChange, let deadline = goalDeadline {
                    let direction = rate < 0 ? "lose" : "gain"
                    let deadlineLabel = deadline.formatted(date: .abbreviated, time: .omitted)
                    Text("\(direction) \(abs(rate).formatted(maxDigits: 2))%/wk to reach goal by \(deadlineLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ZStack {
                BodyFatChart()
                if filteredBodyFatEntries.isEmpty {
                    Text("No body fat data for this period")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func BodyFatChart() -> some View {
        let entries = filteredBodyFatEntries.sorted { $0.date < $1.date }
        let chartMin = bodyFatChartMin
        let chartMax = bodyFatChartMax
        let goalValue = hasBodyFatGoal ? bodyFatGoalPercentage : nil
        let isEmpty = entries.isEmpty
        let showTrajectory = hasBodyFatGoal && hasGoalDeadline && !entries.isEmpty

        Chart {
            ForEach(entries, id: \.date) { entry in
                PointMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Body Fat", entry.percentage)
                )
                .foregroundStyle(Color.orange)
                .symbolSize(30)

                LineMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Body Fat", entry.percentage)
                )
                .foregroundStyle(Color.orange)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    yStart: .value("Baseline", chartMin),
                    yEnd: .value("Body Fat", entry.percentage)
                )
                .foregroundStyle(Color.orange.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }

            if showTrajectory, let current = latestBodyFat, let deadline = goalDeadline {
                let startValue = current.percentage
                let endValue = bodyFatGoalPercentage
                LineMark(
                    x: .value("Date", current.date.toDate() ?? .now, unit: .day),
                    y: .value("Body Fat", startValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))

                LineMark(
                    x: .value("Date", deadline, unit: .day),
                    y: .value("Body Fat", endValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }

            if let goal = goalValue {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.text.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal: \(goal.formatted(maxDigits: 1))%")
                            .font(.caption2)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
            }
        }
        .chartYScale(domain: chartMin...chartMax)
        .chartXScale(domain: chartStartDate...goalChartEndDate)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
        .opacity(isEmpty ? 0.3 : 1)
    }

    // MARK: - Waist Chart

    @ViewBuilder private func WaistChartCard() -> some View {
        VStack(spacing: .spacingDefault) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Waist")
                    .listSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let rate = requiredWeeklyWaistChangeCm, let deadline = goalDeadline {
                    let rateDisplay = preferredWaistUnit.fromCm(abs(rate)).formatted(maxDigits: 2)
                    let direction = rate < 0 ? "lose" : "gain"
                    let deadlineLabel = deadline.formatted(date: .abbreviated, time: .omitted)
                    Text("\(direction) \(rateDisplay) \(preferredWaistUnit.label)/wk to reach goal by \(deadlineLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ZStack {
                WaistChart()
                if filteredWaistEntries.isEmpty {
                    Text("No waist data for this period")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func WaistChart() -> some View {
        let entries = filteredWaistEntries.sorted { $0.date < $1.date }
        let chartMin = waistChartMin
        let chartMax = waistChartMax
        let goalValue = hasWaistGoal ? preferredWaistUnit.fromCm(waistGoalCm) : nil
        let isEmpty = entries.isEmpty
        let showTrajectory = hasWaistGoal && hasGoalDeadline && !entries.isEmpty

        Chart {
            ForEach(entries, id: \.date) { entry in
                let value = preferredWaistUnit.fromCm(entry.circumferenceCm)
                PointMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Waist", value)
                )
                .foregroundStyle(Color.green)
                .symbolSize(30)

                LineMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    y: .value("Waist", value)
                )
                .foregroundStyle(Color.green)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                    yStart: .value("Baseline", chartMin),
                    yEnd: .value("Waist", value)
                )
                .foregroundStyle(Color.green.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }

            if showTrajectory, let current = latestWaist, let deadline = goalDeadline {
                let startValue = preferredWaistUnit.fromCm(current.circumferenceCm)
                let endValue = preferredWaistUnit.fromCm(waistGoalCm)
                LineMark(
                    x: .value("Date", current.date.toDate() ?? .now, unit: .day),
                    y: .value("Waist", startValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))

                LineMark(
                    x: .value("Date", deadline, unit: .day),
                    y: .value("Waist", endValue),
                    series: .value("Series", "trajectory")
                )
                .foregroundStyle(Color.text.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }

            if let goal = goalValue {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.text.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal: \(goal.formatted(maxDigits: 1)) \(preferredWaistUnit.label)")
                            .font(.caption2)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
            }
        }
        .chartYScale(domain: chartMin...chartMax)
        .chartXScale(domain: chartStartDate...goalChartEndDate)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
        .opacity(isEmpty ? 0.3 : 1)
    }

    // MARK: - Goals (Premium)

    @ViewBuilder private func GoalsCards() -> some View {
        let goalMetrics = visibleMetrics.filter { $0 != .bmi }
        if !goalMetrics.isEmpty {
            VStack(spacing: .spacingDefault) {
                Text("Goals")
                    .listSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                PremiumGate(trigger: .weightGoal, feature: "weight_goal") {
                    VStack(spacing: 0) {
                        ForEach(goalMetrics.indices, id: \.self) { i in
                            if i > 0 { Divider().padding(.horizontal) }
                            MetricGoalField(for: goalMetrics[i])
                        }
                        Divider().padding(.horizontal)
                        DeadlineField()
                    }
                    .padding(.vertical, 4)
                    .inCard(backgroundColor: Color.gray)
                }
            }
        }
    }

    @ViewBuilder private func MetricGoalField(for metric: BodyMetric) -> some View {
        switch metric {
        case .weight:
            GoalField(
                title: "Weight",
                value: Binding(
                    get: { hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil },
                    set: { weightGoalKg = $0.map { preferredUnit.toKg($0) } ?? 0 }
                ),
                unit: preferredUnit.label,
                placeholder: "Not set"
            )
        case .bodyFat:
            GoalField(
                title: "Body Fat",
                value: Binding(
                    get: { hasBodyFatGoal ? bodyFatGoalPercentage : nil },
                    set: { bodyFatGoalPercentage = $0 ?? 0 }
                ),
                unit: "%",
                placeholder: "Not set"
            )
        case .waist:
            GoalField(
                title: "Waist",
                value: Binding(
                    get: { hasWaistGoal ? preferredWaistUnit.fromCm(waistGoalCm) : nil },
                    set: { waistGoalCm = $0.map { preferredWaistUnit.toCm($0) } ?? 0 }
                ),
                unit: preferredWaistUnit.label,
                placeholder: "Not set"
            )
        case .bmi:
            EmptyView()
        }
    }

    @ViewBuilder private func DeadlineField() -> some View {
        HStack {
            Text("By")
                .font(.subheadline)
                .fontWeight(.light)
            Spacer()
            if hasGoalDeadline {
                Button("Clear") { bodyGoalDeadlineRaw = 0 }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            } else {
                Button("Set deadline") {
                    let threeMonths = Calendar.current.date(byAdding: .month, value: 3, to: .now)!
                    bodyGoalDeadlineRaw = threeMonths.timeIntervalSinceReferenceDate
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder private func GoalField(
        title: String,
        value: Binding<Double?>,
        unit: String,
        placeholder: String
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.light)
            Spacer()
            TextField(
                placeholder,
                text: Binding(
                    get: {
                        if let v = value.wrappedValue {
                            return v.formatted(maxDigits: 1)
                        }
                        return ""
                    },
                    set: { newValue in
                        if newValue.isEmpty {
                            value.wrappedValue = nil
                        } else if let d = Double(newValue) {
                            value.wrappedValue = d
                        }
                    }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .frame(maxWidth: 100)
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - TDEE / Calorie Target

    @ViewBuilder private func TdeeCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Calorie Target")
                    .listSectionHeader()
                Spacer()
            }
            if let bmrValue = bmr, let tdeeValue = tdee {
                let target = suggestedCalories ?? tdeeValue
                let diff = target - tdeeValue
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Activity Level")
                                .font(.subheadline)
                            Spacer()
                            Picker("Activity Level", selection: $activityLevelRaw) {
                                ForEach(ActivityLevel.allCases) { level in
                                    Text(level.label).tag(level.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: activityLevelRaw) { appliedCalorieGoal = nil }
                        }
                        HStack {
                            Text(activityLevel.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal)

                    HStack {
                        Text("BMR")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(bmrValue.formatted(maxDigits: 0)) kcal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)

                    HStack {
                        Text("TDEE")
                            .font(.subheadline)
                        Spacer()
                        Text("\(tdeeValue.formatted(maxDigits: 0)) kcal")
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)

                    Divider().padding(.horizontal)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Suggested Intake")
                                .font(.subheadline)
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
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider().padding(.horizontal)

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
                                    .foregroundStyle(Color.accentColor)
                            }
                            Spacer()
                        }
                    }
                    .disabled(appliedCalorieGoal != nil)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .padding(.vertical, 4)
                .inCard(backgroundColor: Color.gray)

                Text("**BMR** (Basal Metabolic Rate) is the calories your body burns at rest. **TDEE** (Total Daily Energy Expenditure) adds your activity level on top of that.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(tdeeHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .inCard(backgroundColor: Color.gray)
            }
        }
    }

    // MARK: - History

    @ViewBuilder private func HistoryLink() -> some View {
        NavigationLink {
            WeightHistoryView()
        } label: {
            HStack {
                Text("View History")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.text)
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }

    NavigationStack {
        WeightTrackingView()
    }
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
