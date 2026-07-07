//
//  DashboardDeficiencySection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/29/26.
//

import SwiftUI

struct DashboardDeficiencySection: View {

    private static let averagingDays = 7

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var premiumAnalytics: PremiumAnalytics

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var showMarketingView: Bool = false

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

    private var recentFoods: [ConsumedFood] {
        let startDate = date.adding(days: -(Self.averagingDays - 1))
        return allConsumedFoods.filter { $0.dateLogged >= startDate && $0.dateLogged <= date }
    }

    private var deficientNutrients: [DeficientNutrient] {
        let foods = recentFoods
        guard !foods.isEmpty else { return [] }

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

            for nutrientId in Self.trackedNutrientIds {
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

        return Self.trackedNutrientIds.compactMap { nutrientId in
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

    var body: some View {
        let deficiencies = deficientNutrients

        if !recentFoods.isEmpty {
            if deficiencies.isEmpty {
                OnTrackCard()
            } else if subscriptionManager.isSubscribed {
                DeficiencyCard(deficiencies)
            } else {
                LockedDeficiencyCard(count: deficiencies.count)
            }
        }
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

    @ViewBuilder private func LockedDeficiencyCard(count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Low This Week")
                    .font(.subheadline.bold())
                Text("\(count) nutrient\(count == 1 ? "" : "s") running low — unlock to see which, and foods that would help")
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
            premiumAnalytics.premiumFeatureTapped(feature: "deficiency_insights")
            showMarketingView = true
        }
        .sheet(isPresented: $showMarketingView) {
            MarketingView(trigger: .deficiencyInsights)
        }
    }

    @ViewBuilder private func DeficiencyCard(_ deficiencies: [DeficientNutrient]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Low This Week")
                    .font(.subheadline.bold())
                Spacer()
            }
            Text("Tap a nutrient to see foods that would help")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(deficiencies) { deficiency in
                    NavigationLink {
                        NutrientLibraryDetailView(nutrient: deficiency.nutrient)
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(deficiencyColor(for: deficiency.percentage))
                                .frame(width: 6, height: 6)
                            Text(deficiency.name)
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
            }
        }
        .padding()
        .inCard(backgroundColor: .orange)
    }

    private func deficiencyColor(for percentage: Double) -> Color {
        percentage < 0.25 ? .red : .orange
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return LayoutResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions
        )
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
                DashboardDeficiencySection(
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
                DashboardDeficiencySection(
                    allConsumedFoods: [.dashboardSample],
                    date: .today
                )
            }
            .padding(.horizontal)
        }
    }
    .environmentObject(SubscriptionManager(isForScreenshots: false))
}
