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
    case sevenDay = "7 Days"
    case thirtyDay = "30 Days"
    case ninetyDay = "90 Days"

    var days: Int {
        switch self {
        case .sevenDay: return 7
        case .thirtyDay: return 30
        case .ninetyDay: return 90
        }
    }
}

struct WeightTrackingView: View {

    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var engagementAnalytics: EngagementAnalytics

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("weightGoalKg") private var weightGoalKg: Double = 0
    @AppStorage("bodyFatGoalPercentage") private var bodyFatGoalPercentage: Double = 0
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @Query(sort: \WeightEntry.date, order: .reverse) private var allWeightEntries: [WeightEntry]
    @Query(sort: \BodyFatEntry.date, order: .reverse) private var allBodyFatEntries: [BodyFatEntry]

    @State private var period: WeightTrendPeriod = .thirtyDay
    @State private var showEntrySheet: Bool = false
    @State private var showMarketingView: Bool = false
    @State private var hasImportedHealthKit: Bool = false

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var hasWeightGoal: Bool { weightGoalKg > 0 }
    private var hasBodyFatGoal: Bool { bodyFatGoalPercentage > 0 }

    private var cutoffDate: SimpleDate {
        SimpleDate.today.adding(days: -(period.days - 1))
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

    private var latestWeight: WeightEntry? { allWeightEntries.first }
    private var previousWeight: WeightEntry? { allWeightEntries.dropFirst().first }
    private var latestBodyFat: BodyFatEntry? { allBodyFatEntries.first }
    private var previousBodyFat: BodyFatEntry? { allBodyFatEntries.dropFirst().first }

    private var weightTrend: Double? {
        guard let latest = latestWeight, let previous = previousWeight else { return nil }
        return latest.weightKg - previous.weightKg
    }

    private var bodyFatTrend: Double? {
        guard let latest = latestBodyFat, let previous = previousBodyFat else { return nil }
        return latest.percentage - previous.percentage
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

    private func importHealthKitData() {
        guard healthSyncEnabled, !hasImportedHealthKit else { return }
        hasImportedHealthKit = true

        Task {
            let _ = await HealthKitManager.shared.requestAuthorization()
            let weightHistory = await HealthKitManager.shared.fetchWeightHistory()
            let bodyFatHistory = await HealthKitManager.shared.fetchBodyFatHistory()

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

                try? modelContext.save()
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 2 * .spacingDefault) {
                NativeAdListRow(ad: $ad, size: .small)
                CurrentValues()
                PeriodPicker()
                WeightChartCard()
                BodyFatChartCard()
                GoalsCards()
                HistoryLink()
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Body")
        .toolbar { Toolbar() }
        .onAppear { importHealthKitData() }
        .sheet(isPresented: $showEntrySheet) {
            WeightEntrySheet()
        }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .weightGoal)
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
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
        HStack(spacing: .spacingDefault) {
            CurrentWeightCard()
            CurrentBodyFatCard()
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
            HStack {
                Text("Weight")
                    .listSectionHeader()
                Spacer()
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
        let showBars = period == .sevenDay
        let isEmpty = entries.isEmpty

        Chart {
            ForEach(entries, id: \.date) { entry in
                let value = preferredUnit.fromKg(entry.weightKg)
                if showBars {
                    BarMark(
                        x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                        yStart: .value("Baseline", chartMin),
                        yEnd: .value("Weight", value)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                } else {
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
        .chartXScale(domain: chartStartDate...chartEndDate)
        .chartXAxis {
            if showBars {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                }
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
            HStack {
                Text("Body Fat")
                    .listSectionHeader()
                Spacer()
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
        let showBars = period == .sevenDay
        let isEmpty = entries.isEmpty

        Chart {
            ForEach(entries, id: \.date) { entry in
                if showBars {
                    BarMark(
                        x: .value("Date", entry.date.toDate() ?? .now, unit: .day),
                        yStart: .value("Baseline", chartMin),
                        yEnd: .value("Body Fat", entry.percentage)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                } else {
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
        .chartXScale(domain: chartStartDate...chartEndDate)
        .chartXAxis {
            if showBars {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                }
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
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Goals")
                    .listSectionHeader()
                if !subscriptionManager.isSubscribed {
                    Text("PREMIUM")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().foregroundStyle(Color.accentColor.gradient)
                        }
                }
                Spacer()
            }
            VStack(spacing: 0) {
                GoalField(
                    title: "Weight",
                    value: Binding(
                        get: { hasWeightGoal ? preferredUnit.fromKg(weightGoalKg) : nil },
                        set: { newValue in
                            if let v = newValue {
                                weightGoalKg = preferredUnit.toKg(v)
                            } else {
                                weightGoalKg = 0
                            }
                        }
                    ),
                    unit: preferredUnit.label,
                    placeholder: "Not set"
                )
                Divider().padding(.horizontal)
                GoalField(
                    title: "Body Fat",
                    value: Binding(
                        get: { hasBodyFatGoal ? bodyFatGoalPercentage : nil },
                        set: { newValue in
                            bodyFatGoalPercentage = newValue ?? 0
                        }
                    ),
                    unit: "%",
                    placeholder: "Not set"
                )
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
            .contentShape(Rectangle())
            .onTapGesture {
                if !subscriptionManager.isSubscribed {
                    showMarketingView = true
                }
            }
            .allowsHitTesting(subscriptionManager.isSubscribed ? true : true)
        }
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
            if subscriptionManager.isSubscribed {
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
            } else {
                Text(placeholder)
                    .foregroundStyle(.secondary)
            }
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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

    NavigationStack {
        WeightTrackingView()
    }
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
