//
//  DashboardWeeklyNutrientWatchSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/29/26.
//

import SwiftUI

/// Combines the "running low" (deficiency) and "over the upper limit" (high) weekly signals
/// into a single card, since both are the same "things to watch this week" concept and
/// share the same 7-day window.
struct DashboardWeeklyNutrientWatchSection: View {

    private static let windowDays = 7

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var premiumAnalytics: PremiumAnalytics

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showMarketingView: Bool = false
    @State private var deficiencies: [DeficientNutrient] = []
    @State private var highNutrients: [HighNutrient] = []

    let allConsumedFoods: [ConsumedFood]
    let date: SimpleDate

    private var user: User { userService.currentUser }

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
        let startDate = date.adding(days: -(Self.windowDays - 1))
        return allConsumedFoods.filter { $0.dateLogged >= startDate && $0.dateLogged <= date }
    }

    private func updateWeeklyNutrients() {
        let foods = recentFoods
        guard !foods.isEmpty else {
            deficiencies = []
            highNutrients = []
            return
        }

        let user = self.user
        let rdiLibrary = self.rdiLibrary
        let remoteDatabase = self.remoteDatabase

        Task {
            deficiencies = Self.computeDeficientNutrients(
                foods: foods,
                user: user,
                rdiLibrary: rdiLibrary,
                remoteDatabase: remoteDatabase
            )
            highNutrients = Self.computeHighNutrients(
                foods: foods,
                user: user,
                rdiLibrary: rdiLibrary,
                remoteDatabase: remoteDatabase
            )
        }
    }

    // Hits the on-disk food database, so this must run off the main thread
    // (called from a Task) rather than as a view body computed property.
    private static func computeDeficientNutrients(
        foods: [ConsumedFood],
        user: User,
        rdiLibrary: NutrientRdiLibrary,
        remoteDatabase: RemoteDatabase
    ) -> [DeficientNutrient] {
        let foodsByDate = Dictionary(grouping: foods) { $0.dateLogged }
        let daysWithData = foodsByDate.count

        var totalsByNutrient: [String: (total: Double, nutrient: Nutrient)] = [:]

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

            for nutrientId in trackedNutrientIds {
                let pairs = dayAggregator.nutrientsByNutrientNumber[nutrientId] ?? []
                let amount = pairs.reduce(into: 0.0) { $0 += $1.nutrient.amount }

                if var existing = totalsByNutrient[nutrientId] {
                    existing.total += amount
                    totalsByNutrient[nutrientId] = existing
                } else {
                    let nutrient = pairs.first?.nutrient
                        ?? remoteDatabase.getNutrient(withId: nutrientId)
                        ?? Nutrient(fdcNumber: nutrientId, name: "Unknown", unitName: "")
                    totalsByNutrient[nutrientId] = (total: amount, nutrient: nutrient)
                }
            }
        }

        return trackedNutrientIds.compactMap { nutrientId in
            let rdi = NutrientGoalDefaults.effectiveRdi(
                for: nutrientId,
                user: user,
                rdiLibrary: rdiLibrary
            )
            guard let rdi, rdi.recommendedAmount > 0 else { return nil }

            guard let entry = totalsByNutrient[nutrientId] else { return nil }
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

    // Hits the on-disk food database, so this must run off the main thread
    // (called from a Task) rather than as a view body computed property.
    private static func computeHighNutrients(
        foods: [ConsumedFood],
        user: User,
        rdiLibrary: NutrientRdiLibrary,
        remoteDatabase: RemoteDatabase
    ) -> [HighNutrient] {
        let foodsByDate = Dictionary(grouping: foods) { $0.dateLogged }
        let daysWithData = foodsByDate.count
        guard daysWithData > 0 else { return [] }

        var totalsByNutrient: [String: (total: Double, nutrient: Nutrient)] = [:]

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

            for nutrientId in trackedNutrientIds {
                let pairs = dayAggregator.nutrientsByNutrientNumber[nutrientId] ?? []
                let amount = pairs.reduce(into: 0.0) { $0 += $1.nutrient.amount }

                if var existing = totalsByNutrient[nutrientId] {
                    existing.total += amount
                    totalsByNutrient[nutrientId] = existing
                } else {
                    let nutrient = pairs.first?.nutrient
                        ?? remoteDatabase.getNutrient(withId: nutrientId)
                        ?? Nutrient(fdcNumber: nutrientId, name: "Unknown", unitName: "")
                    totalsByNutrient[nutrientId] = (total: amount, nutrient: nutrient)
                }
            }
        }

        return trackedNutrientIds.compactMap { nutrientId -> HighNutrient? in
            guard let rdi = NutrientGoalDefaults.effectiveRdi(
                for: nutrientId,
                user: user,
                rdiLibrary: rdiLibrary
            ) else { return nil }

            guard let entry = totalsByNutrient[nutrientId] else { return nil }
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

    private func colorPalette(for nutrientId: String) -> ColorPalette {
        let groupKey = DashboardVitaminsSection.orderedWhitelist.contains(nutrientId)
            ? FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents
            : FdcNutrientGroupMapper.GroupNumber_Minerals
        return ColorPaletteService.getColorPaletteFor(number: groupKey)
    }

    private func deficiencyColor(for percentage: Double) -> Color {
        percentage < 0.25 ? .red : .orange
    }

    private func summaryText(lowCount: Int, highCount: Int) -> String {
        var parts: [String] = []
        if lowCount > 0 { parts.append("\(lowCount) running low") }
        if highCount > 0 { parts.append("\(highCount) over the limit") }
        return parts.joined(separator: ", ") + " this week — unlock to see which"
    }

    var body: some View {
        Group {
            if !recentFoods.isEmpty {
                if deficiencies.isEmpty && highNutrients.isEmpty {
                    OnTrackCard()
                } else if subscriptionManager.isSubscribed {
                    WeeklyWatchCard()
                } else {
                    LockedWeeklyWatchCard(lowCount: deficiencies.count, highCount: highNutrients.count)
                }
            }
        }
        .onChange(of: date, initial: true) { updateWeeklyNutrients() }
        .onChange(of: allConsumedFoods) { updateWeeklyNutrients() }
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

    @ViewBuilder private func LockedWeeklyWatchCard(lowCount: Int, highCount: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("This Week")
                    .font(.subheadline.bold())
                Text(summaryText(lowCount: lowCount, highCount: highCount))
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
                Text("This Week")
                    .font(.subheadline.bold())
                Spacer()
            }
            Text("Tap a nutrient to see foods that would help, or its trend")
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
        }
        .padding()
        .inCard(backgroundColor: .orange)
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
