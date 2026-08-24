//
//  NutrientTrendView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import SwiftData

enum TrendPeriod: String, CaseIterable {
    case sevenDay = "7 Days"
    case thirtyDay = "30 Days"

    var days: Int {
        switch self {
        case .sevenDay: return 7
        case .thirtyDay: return 30
        }
    }
}

struct NutrientTrendView: View {

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics

    @State private var period: TrendPeriod = .sevenDay
    @State private var dailyTotals: [DailyNutrientTotal] = []
    @State private var isLoading: Bool = true

    let nutrient: Nutrient
    let colorPalette: ColorPalette

    private var user: User { userService.currentUser }

    private var rdi: LifeStageNutrientRdi? {
        NutrientGoalDefaults.effectiveRdi(
            for: nutrient.fdcNumber,
            user: user,
            rdiLibrary: rdiLibrary
        )
    }

    private var chartRdi: LifeStageNutrientRdi? {
        guard let rdi else { return nil }
        let foodsUnit = WeightUnit.unitFrom(nutrient)
        if foodsUnit == rdi.unit { return rdi }
        return rdi.convertedTo(foodsUnit)
    }

    /// Summary stats only consider days that have food logged, so that days the
    /// user skipped logging don't drag the numbers down.
    private var loggedDays: [DailyNutrientTotal] {
        dailyTotals.filter(\.hasLoggedFoods)
    }

    private var average: Double {
        guard !loggedDays.isEmpty else { return 0 }
        return loggedDays.reduce(0) { $0 + $1.amount } / Double(loggedDays.count)
    }

    private var highestDay: DailyNutrientTotal? {
        loggedDays.max(by: { $0.amount < $1.amount })
    }

    private var lowestDay: DailyNutrientTotal? {
        loggedDays.min(by: { $0.amount < $1.amount })
    }

    private var daysAboveGoal: Int? {
        guard let rdi = chartRdi, rdi.recommendedAmount > 0, rdi.recommendedAmount < .greatestFiniteMagnitude else {
            return nil
        }
        return loggedDays.filter { $0.amount >= rdi.recommendedAmount }.count
    }

    private func loadData() {
        isLoading = true

        Task {
            let range = NutrientTrendDataProvider.dateRange(days: period.days, endingOn: .today)

            let startDate = range.start
            let endDate = range.end
            let descriptor = FetchDescriptor<ConsumedFood>(
                predicate: #Predicate { food in
                    food.dateLogged >= startDate && food.dateLogged <= endDate
                }
            )
            let consumedFoods = (try? modelContext.fetch(descriptor)) ?? []

            let provider = NutrientTrendDataProvider(remoteDatabase: remoteDatabase)
            let totals = provider.dailyTotals(
                for: nutrient.fdcNumber,
                consumedFoods: consumedFoods,
                startDate: range.start,
                endDate: range.end
            )

            await MainActor.run {
                dailyTotals = totals
                isLoading = false
            }
        }
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
        .onAppear { engagementAnalytics.trendNutrientViewed(nutrientName: nutrient.name) }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("\(nutrient.name) Trends")
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
                    rdi: chartRdi,
                    accentColor: colorPalette.accent,
                    unitName: nutrient.unitName
                )
                .listRowDefaultModifiers()
            }
        }
    }

    @ViewBuilder private func SummarySection() -> some View {
        if !isLoading {
            Section {
                if loggedDays.isEmpty {
                    Text("No foods logged in this period.")
                        .foregroundStyle(Color.text.opacity(0.5))
                        .listRowDefaultModifiers()
                } else {
                    SummaryRow(
                        label: "Daily Average",
                        value: "\(average.formatted(maxDigits: 1))\(nutrient.unitName)"
                    )
                    if let daysAboveGoal {
                        SummaryRow(
                            label: "Days at Goal",
                            value: "\(daysAboveGoal) of \(loggedDays.count)"
                        )
                    }
                    if let highestDay {
                        SummaryRow(
                            label: "Highest Day",
                            value: "\(highestDay.amount.formatted(maxDigits: 1))\(nutrient.unitName)",
                            detail: highestDay.date.formatted()
                        )
                    }
                    if let lowestDay {
                        SummaryRow(
                            label: "Lowest Day",
                            value: "\(lowestDay.amount.formatted(maxDigits: 1))\(nutrient.unitName)",
                            detail: lowestDay.date.formatted()
                        )
                    }
                }
            } header: {
                Text("Summary")
            } footer: {
                if !loggedDays.isEmpty, loggedDays.count < dailyTotals.count {
                    Text("Based on the \(loggedDays.count) days with logged food. Days without any logged food are left out.")
                }
            }
        }
    }

    @ViewBuilder private func SummaryRow(
        label: String,
        value: String,
        detail: String? = nil
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            VStack(alignment: .trailing) {
                Text(value)
                    .bold()
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
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        NutrientTrendView(
            nutrient: Nutrient(fdcNumber: "301", name: "Calcium", unitName: "mg"),
            colorPalette: ColorPalettes.mint
        )
    }
}
