//
//  WaterTrendView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import SwiftUI
import SwiftData

struct WaterTrendView: View {

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var remoteDatabase: RemoteDatabase

    let waterUnit: WaterUnit

    @State private var period: TrendPeriod = .sevenDay
    @State private var dailyTotals: [DailyNutrientTotal] = []
    @State private var isLoading: Bool = true

    private var user: User { userService.currentUser }

    private var goalGrams: Double {
        if let custom = user.waterGoalGrams { return custom }
        return rdiLibrary
            .getRdis(FdcNutrientGroupMapper.NutrientNumber_Water)?
            .getRdi(user)?
            .recommendedAmount ?? 0
    }

    private var goalInUnit: Double { waterUnit.fromGrams(goalGrams) }

    private var rdiForChart: LifeStageNutrientRdi? {
        guard goalGrams > 0 else { return nil }
        return LifeStageNutrientRdi.create(
            nutrientFdcNumber: FdcNutrientGroupMapper.NutrientNumber_Water,
            gender: user.gender,
            minAgeYears: 0,
            maxAgeYears: .greatestFiniteMagnitude,
            recommendedAmount: goalInUnit,
            upperLimit: .greatestFiniteMagnitude,
            unit: .gram
        )
    }

    private var average: Double {
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.reduce(0) { $0 + $1.amount } / Double(dailyTotals.count)
    }

    private var highestDay: DailyNutrientTotal? { dailyTotals.max(by: { $0.amount < $1.amount }) }
    private var lowestDay: DailyNutrientTotal? { dailyTotals.min(by: { $0.amount < $1.amount }) }

    private var daysAtGoal: Int? {
        guard goalInUnit > 0 else { return nil }
        return dailyTotals.filter { $0.amount >= goalInUnit }.count
    }

    private func loadData() {
        let range = NutrientTrendDataProvider.dateRange(days: period.days, endingOn: .today)
        let startDate = range.start
        let endDate = range.end

        let waterEntryDescriptor = FetchDescriptor<WaterEntry>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate }
        )
        let entries = (try? modelContext.fetch(waterEntryDescriptor)) ?? []
        let waterData = entries.map { (date: $0.date, amountGrams: $0.amountGrams) }

        let consumedFoodDescriptor = FetchDescriptor<ConsumedFood>(
            predicate: #Predicate { food in
                food.dateLogged >= startDate && food.dateLogged <= endDate
            }
        )
        let consumedFoods = (try? modelContext.fetch(consumedFoodDescriptor)) ?? []
        let foodWaterTotals = NutrientTrendDataProvider(remoteDatabase: remoteDatabase).dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Water,
            consumedFoods: consumedFoods,
            startDate: startDate,
            endDate: endDate
        )
        let foodWaterGramsByDate = Dictionary(uniqueKeysWithValues: foodWaterTotals.map { ($0.date, $0.amount) })

        dailyTotals = WaterTrendDataProvider().dailyTotals(
            directWaterData: waterData,
            foodWaterGramsByDate: foodWaterGramsByDate,
            startDate: startDate,
            endDate: endDate,
            unit: waterUnit
        )
        isLoading = false
    }

    var body: some View {
        List {
            PeriodPicker()
            ChartSection()
            SummarySection()
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .onChange(of: period, initial: true) { loadData() }
        .onAppear {
            engagementAnalytics.trendNutrientViewed(nutrientName: "Water")
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Water Trends")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "arrow.backward")
            }
        }
    }

    @ViewBuilder private func PeriodPicker() -> some View {
        Picker("Period", selection: $period) {
            ForEach(TrendPeriod.allCases, id: \.self) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func ChartSection() -> some View {
        Section {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 200)
                .listRowDefaultModifiers()
            } else {
                NutrientTrendChart(
                    dailyTotals: dailyTotals,
                    rdi: rdiForChart,
                    accentColor: .blue,
                    unitName: waterUnit.rawValue
                )
                .listRowDefaultModifiers()
            }
        }
    }

    @ViewBuilder private func SummarySection() -> some View {
        if !isLoading {
            Section {
                SummaryRow(
                    label: "Daily Average",
                    value: "\(average.formatted(maxDigits: 1)) \(waterUnit.rawValue)"
                )
                if let daysAtGoal {
                    SummaryRow(
                        label: "Days at Goal",
                        value: "\(daysAtGoal) of \(dailyTotals.count)"
                    )
                }
                if let highestDay {
                    SummaryRow(
                        label: "Highest Day",
                        value: "\(highestDay.amount.formatted(maxDigits: 1)) \(waterUnit.rawValue)",
                        detail: highestDay.date.formatted()
                    )
                }
                if let lowestDay {
                    SummaryRow(
                        label: "Lowest Day",
                        value: "\(lowestDay.amount.formatted(maxDigits: 1)) \(waterUnit.rawValue)",
                        detail: lowestDay.date.formatted()
                    )
                }
            } header: {
                Text("Summary")
            }
        }
    }

    @ViewBuilder private func SummaryRow(label: String, value: String, detail: String? = nil) -> some View {
        HStack {
            Text(label)
            Spacer()
            VStack(alignment: .trailing) {
                Text(value).bold()
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(Color.text.opacity(0.5))
                }
            }
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        WaterTrendView(waterUnit: .cups)
    }
    .modelContainer(for: WaterEntry.self, inMemory: true)
}
