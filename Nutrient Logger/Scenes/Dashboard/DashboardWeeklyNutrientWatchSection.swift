//
//  DashboardWeeklyNutrientWatchSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/29/26.
//

import SwiftUI

/// The lookback window the weekly watch card uses to compute lows/highs/balances. User-configurable
/// in Nutrition Settings; defaults to 7 days. Shared by the card and the settings screen.
enum WeeklyWatchWindow {
    static let appStorageKey = "weeklyWatch_windowDays"
    static let defaultDays = 7
    static let options = [1, 3, 7, 14, 30]

    /// Card header, e.g. "Today" for 1 day, "This Week" for 7, otherwise "Last N Days".
    static func title(forDays days: Int) -> String {
        switch days {
        case 1: return "Today"
        case 7: return "This Week"
        default: return "Last \(days) Days"
        }
    }

    /// Trailing phrase for the locked-card summary, e.g. "today" / "this week" / "in the last 14 days".
    static func summarySuffix(forDays days: Int) -> String {
        switch days {
        case 1: return "today"
        case 7: return "this week"
        default: return "in the last \(days) days"
        }
    }

    /// Menu label for the picker, e.g. "1 day" / "7 days".
    static func optionLabel(forDays days: Int) -> String {
        days == 1 ? "1 day" : "\(days) days"
    }
}

/// Combines the "running low" (deficiency), "over the upper limit" (high), and "out of balance"
/// (ratio) signals into a single card, since all three are the same "things to watch" concept and
/// share the same lookback window (configurable; 7 days by default).
struct DashboardWeeklyNutrientWatchSection: View {

    @AppStorage(WeeklyWatchWindow.appStorageKey) private var windowDays: Int = WeeklyWatchWindow.defaultDays

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var premiumAnalytics: PremiumAnalytics

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showMarketingView: Bool = false
    @State private var deficiencies: [DeficientNutrient] = []
    @State private var highNutrients: [HighNutrient] = []
    @State private var balances: [NutrientBalanceResult] = []
    @State private var selectedBalance: NutrientBalanceResult?

    @AppStorage(NutrientBalanceSettings.hiddenKey) private var balanceHiddenRaw: String = ""
    @AppStorage(NutrientBalanceSettings.customKey) private var balanceCustomRaw: String = ""

    let allConsumedFoods: [ConsumedFood]
    let date: SimpleDate

    /// When set, lows/highs resolve against this user instead of the signed-in one. Used only by the
    /// onboarding demo dashboard so it can show a reference-adult watch card without a real profile.
    var userOverride: User?

    private var user: User { userOverride ?? userService.currentUser }

    private var effectiveRatios: [NutrientRatio] {
        NutrientBalanceSettings.effectiveRatios(hiddenRaw: balanceHiddenRaw, customRaw: balanceCustomRaw)
    }

    private static let trackedNutrientIds: [String] =
        DashboardVitaminsSection.orderedWhitelist + DashboardMineralsSection.orderedWhitelist

    struct DeficientNutrient: Identifiable {
        let id: String
        let name: String
        let percentage: Double
        let nutrient: Nutrient
    }

    struct HighNutrient: Identifiable {
        let id: String
        let name: String
        let percentageOfLimit: Double
        let nutrient: Nutrient
    }

    private var recentFoods: [ConsumedFood] {
        let startDate = date.adding(days: -(windowDays - 1))
        return allConsumedFoods.filter { $0.dateLogged >= startDate && $0.dateLogged <= date }
    }

    private func updateWeeklyNutrients() {
        let foods = recentFoods
        guard !foods.isEmpty else {
            deficiencies = []
            highNutrients = []
            balances = []
            return
        }

        let user = self.user
        let rdiLibrary = self.rdiLibrary
        let remoteDatabase = self.remoteDatabase
        let ratios = self.effectiveRatios

        Task {
            let results = Self.computeWeeklyWatch(
                foods: foods,
                ratios: ratios,
                user: user,
                rdiLibrary: rdiLibrary,
                remoteDatabase: remoteDatabase
            )
            deficiencies = results.deficiencies
            highNutrients = results.highNutrients
            balances = results.balances
        }
    }

    private struct WeeklyWatchResults {
        var deficiencies: [DeficientNutrient] = []
        var highNutrients: [HighNutrient] = []
        var balances: [NutrientBalanceResult] = []
    }

    // Hits the on-disk food database, so this must run off the main thread (called from a Task)
    // rather than as a view body computed property. All three signals share one aggregation pass
    // over the week's foods so the database is only read once.
    private static func computeWeeklyWatch(
        foods: [ConsumedFood],
        ratios: [NutrientRatio],
        user: User,
        rdiLibrary: NutrientRdiLibrary,
        remoteDatabase: RemoteDatabase
    ) -> WeeklyWatchResults {
        let ratioIds = ratios.flatMap { $0.allNutrientIds }
        let idsToAggregate = Set(trackedNutrientIds).union(ratioIds)
        let (daysWithData, totals) = aggregateTotals(
            foods: foods,
            nutrientIds: idsToAggregate,
            remoteDatabase: remoteDatabase
        )
        guard daysWithData > 0 else { return WeeklyWatchResults() }

        return WeeklyWatchResults(
            deficiencies: computeDeficiencies(totals: totals, daysWithData: daysWithData, user: user, rdiLibrary: rdiLibrary),
            highNutrients: computeHighs(totals: totals, daysWithData: daysWithData, user: user, rdiLibrary: rdiLibrary),
            balances: computeBalances(totals: totals, ratios: ratios)
        )
    }

    /// Sums each nutrient's daily intake across the days that have logged food, keeping one
    /// representative `Nutrient` (for its unit/name) per id. Grouping by date means empty days
    /// don't count against the average, matching how deficiencies are measured.
    private static func aggregateTotals(
        foods: [ConsumedFood],
        nutrientIds: Set<String>,
        remoteDatabase: RemoteDatabase
    ) -> (daysWithData: Int, totals: [String: (total: Double, nutrient: Nutrient)]) {
        let foodsByDate = Dictionary(grouping: foods) { $0.dateLogged }
        var totals: [String: (total: Double, nutrient: Nutrient)] = [:]

        for (_, dayFoods) in foodsByDate {
            let foodItems: [FoodItem] = dayFoods.compactMap { consumedFood in
                do {
                    var food = try remoteDatabase.getFood(String(consumedFood.fdcId))
                    food = try food?.applyingPortion(consumedFood.portion)
                    return food
                } catch {
                    return nil
                }
            }

            let dayAggregator = NutrientDataAggregator(foodItems)

            for nutrientId in nutrientIds {
                let pairs = dayAggregator.nutrientsByNutrientNumber[nutrientId] ?? []
                let amount = pairs.reduce(into: 0.0) { $0 += $1.nutrient.amount }

                if var existing = totals[nutrientId] {
                    existing.total += amount
                    totals[nutrientId] = existing
                } else {
                    let nutrient = pairs.first?.nutrient
                        ?? remoteDatabase.getNutrient(withId: nutrientId)
                        ?? Nutrient(fdcNumber: nutrientId, name: "Unknown", unitName: "")
                    totals[nutrientId] = (total: amount, nutrient: nutrient)
                }
            }
        }

        return (foodsByDate.count, totals)
    }

    private static func computeDeficiencies(
        totals: [String: (total: Double, nutrient: Nutrient)],
        daysWithData: Int,
        user: User,
        rdiLibrary: NutrientRdiLibrary
    ) -> [DeficientNutrient] {
        trackedNutrientIds.compactMap { nutrientId in
            let rdi = NutrientGoalDefaults.effectiveRdi(
                for: nutrientId,
                user: user,
                rdiLibrary: rdiLibrary
            )
            guard let rdi, rdi.recommendedAmount > 0 else { return nil }

            guard let entry = totals[nutrientId] else { return nil }
            let averageAmount = entry.total / Double(daysWithData)

            let foodsUnit = WeightUnit.unitFrom(entry.nutrient)
            let convertedRdi = (foodsUnit == rdi.unit) ? rdi : rdi.convertedTo(foodsUnit)

            let percentage = averageAmount / convertedRdi.recommendedAmount
            guard percentage < 0.5 else { return nil }

            let displayName = FdcNutrientGroupMapper.nutrientDisplayNames[nutrientId] ?? entry.nutrient.name

            return DeficientNutrient(
                id: nutrientId,
                name: displayName,
                percentage: percentage,
                nutrient: entry.nutrient
            )
        }
        .sorted { $0.percentage < $1.percentage }
    }

    private static func computeHighs(
        totals: [String: (total: Double, nutrient: Nutrient)],
        daysWithData: Int,
        user: User,
        rdiLibrary: NutrientRdiLibrary
    ) -> [HighNutrient] {
        trackedNutrientIds.compactMap { nutrientId -> HighNutrient? in
            guard let rdi = NutrientGoalDefaults.effectiveRdi(
                for: nutrientId,
                user: user,
                rdiLibrary: rdiLibrary
            ) else { return nil }

            guard let entry = totals[nutrientId] else { return nil }
            let averageAmount = entry.total / Double(daysWithData)

            let foodsUnit = WeightUnit.unitFrom(entry.nutrient)
            let convertedRdi = (foodsUnit == rdi.unit) ? rdi : rdi.convertedTo(foodsUnit)

            guard let result = HighLimitCalculator.evaluate(
                averageAmount: averageAmount,
                upperLimit: convertedRdi.upperLimit
            ) else {
                return nil
            }

            let displayName = FdcNutrientGroupMapper.nutrientDisplayNames[nutrientId] ?? entry.nutrient.name

            return HighNutrient(
                id: nutrientId,
                name: displayName,
                percentageOfLimit: result.percentageOfLimit,
                nutrient: entry.nutrient
            )
        }
        .sorted { $0.percentageOfLimit > $1.percentageOfLimit }
    }

    private static func computeBalances(
        totals: [String: (total: Double, nutrient: Nutrient)],
        ratios: [NutrientRatio]
    ) -> [NutrientBalanceResult] {
        // Convert every side to a common unit (grams) so a ratio is unitless and sides made of
        // different nutrients still add up. Ratios cancel the day count, so raw totals are fine.
        var gramsByNutrient: [String: Double] = [:]
        for (id, entry) in totals {
            let unit = WeightUnit.unitFrom(entry.nutrient)
            gramsByNutrient[id] = unit.convertTo(.gram, entry.total)
        }

        return ratios
            .compactMap { NutrientBalanceCalculator.evaluate(ratio: $0, gramsByNutrient: gramsByNutrient) }
            .sorted { $0.severity > $1.severity }
    }

    private func colorPalette(for nutrientId: String) -> ColorPalette {
        let groupKey = DashboardVitaminsSection.orderedWhitelist.contains(nutrientId)
            ? FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents
            : FdcNutrientGroupMapper.GroupNumber_Minerals
        return ColorPaletteService.getColorPaletteFor(number: groupKey)
    }

    private func deficiencyColor(for percentage: Double) -> Color {
        percentage < 0.25 ? .red : .orange
    }

    private var hasAnyWatchItems: Bool {
        !deficiencies.isEmpty || !highNutrients.isEmpty || !balances.isEmpty
    }

    private func summaryText(lowCount: Int, highCount: Int, balanceCount: Int) -> String {
        var parts: [String] = []
        if lowCount > 0 { parts.append("\(lowCount) running low") }
        if highCount > 0 { parts.append("\(highCount) over the limit") }
        if balanceCount > 0 { parts.append("\(balanceCount) out of balance") }
        let suffix = WeeklyWatchWindow.summarySuffix(forDays: windowDays)
        return parts.joined(separator: ", ") + " \(suffix) — unlock to see which"
    }

    var body: some View {
        Group {
            if !recentFoods.isEmpty {
                if !hasAnyWatchItems {
                    OnTrackCard()
                } else if subscriptionManager.isSubscribed {
                    WeeklyWatchCard()
                } else {
                    LockedWeeklyWatchCard(
                        lowCount: deficiencies.count,
                        highCount: highNutrients.count,
                        balanceCount: balances.count
                    )
                }
            }
        }
        .onChange(of: date, initial: true) { updateWeeklyNutrients() }
        .onChange(of: allConsumedFoods) { updateWeeklyNutrients() }
        .onChange(of: balanceHiddenRaw) { updateWeeklyNutrients() }
        .onChange(of: balanceCustomRaw) { updateWeeklyNutrients() }
        .onChange(of: windowDays) { updateWeeklyNutrients() }
    }

    @ViewBuilder private func OnTrackCard() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("All nutrients on track")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .inCard(backgroundColor: .green)
    }

    @ViewBuilder private func LockedWeeklyWatchCard(lowCount: Int, highCount: Int, balanceCount: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(WeeklyWatchWindow.title(forDays: windowDays))
                    .font(.subheadline.bold())
                Text(summaryText(lowCount: lowCount, highCount: highCount, balanceCount: balanceCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .foregroundStyle(.white)
                .padding(6)
                .background { Circle().fill(Color.accentColor.gradient) }
        }
        .padding()
        .inCard(backgroundColor: .orange)
        .contentShape(Rectangle())
        .onTapGesture {
            premiumAnalytics.premiumFeatureTapped(feature: "weekly_nutrient_watch")
            showMarketingView = true
        }
        .sheet(isPresented: $showMarketingView) {
            MarketingView(trigger: .weeklyNutrientWatch)
        }
    }

    @ViewBuilder private func WeeklyWatchCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(WeeklyWatchWindow.title(forDays: windowDays))
                    .font(.subheadline.bold())
                Spacer()
            }
            Text("Tap an item for foods that would help, its trend, or what a balance means")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !deficiencies.isEmpty {
                SubsectionLabel("Low", color: .orange)
                FlowLayout(spacing: 6) {
                    ForEach(deficiencies) { deficiency in
                        NavigationLink {
                            NutrientLibraryDetailView(nutrient: deficiency.nutrient)
                        } label: {
                            Chip(dotColor: deficiencyColor(for: deficiency.percentage), text: deficiency.name)
                        }
                    }
                }
            }

            if !highNutrients.isEmpty {
                SubsectionLabel("High", color: .red)
                FlowLayout(spacing: 6) {
                    ForEach(highNutrients) { high in
                        NavigationLink {
                            NutrientTrendView(
                                nutrient: high.nutrient,
                                colorPalette: colorPalette(for: high.id)
                            )
                        } label: {
                            Chip(dotColor: .red, text: high.name)
                        }
                    }
                }
            }

            if !balances.isEmpty {
                SubsectionLabel("Out of Balance", color: .purple)
                FlowLayout(spacing: 6) {
                    ForEach(balances) { balance in
                        Button {
                            selectedBalance = balance
                        } label: {
                            Chip(dotColor: .purple, text: "\(balance.name) · \(balance.ratioText)")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .inCard(backgroundColor: .orange)
        .sheet(item: $selectedBalance) { balance in
            BalanceInfoSheet(balance)
        }
    }

    @ViewBuilder private func BalanceInfoSheet(_ balance: NutrientBalanceResult) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.purple)
                        Text(balance.name)
                            .font(.title2.bold())
                    }

                    HStack(spacing: 12) {
                        BalanceStat(title: "Your week", value: balance.ratioText, color: .purple)
                        BalanceStat(title: "Target", value: balance.targetText.replacingOccurrences(of: "Aim for ", with: ""), color: .green)
                    }

                    Text(balance.explanation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { selectedBalance = nil }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder private func BalanceStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.gray.opacity(0.12)))
    }

    @ViewBuilder private func SubsectionLabel(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.caption2.bold())
            .foregroundStyle(color)
    }

    @ViewBuilder private func Chip(dotColor: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
        )
        .foregroundStyle(Color.text)
    }
}

#Preview("Subscriber") {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }

    NavigationStack {
        ScrollView {
            VStack {
                DashboardWeeklyNutrientWatchSection(
                    allConsumedFoods: [.dashboardSample],
                    date: .today
                )
            }
            .padding(.horizontal)
        }
    }
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}

#Preview("Free user") {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }

    NavigationStack {
        ScrollView {
            VStack {
                DashboardWeeklyNutrientWatchSection(
                    allConsumedFoods: [.dashboardSample],
                    date: .today
                )
            }
            .padding(.horizontal)
        }
    }
    .environmentObject(SubscriptionManager(isForScreenshots: false))
}
