//
//  OnboardingFoodBreakdownView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/7/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Onboarding step: tap a familiar food that fits your diet and see everything in one serving, not
/// just the four numbers most trackers stop at. Flags the diet's usual gaps the food leaves out, which
/// sets up the full sample day that follows.
struct OnboardingFoodBreakdownView: View {

    let diet: NutritionDietPreset
    let onContinue: () -> Void

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var engagementAnalytics: EngagementAnalytics

    @State private var selected: OnboardingBreakdownFood?
    @State private var breakdown: FoodBreakdown?
    @State private var calories: Double?

    private static let micronutrients = DashboardVitaminsSection.orderedWhitelist + DashboardMineralsSection.orderedWhitelist

    private func select(_ food: OnboardingBreakdownFood) {
        guard food != selected else { return }
        engagementAnalytics.onboardingFoodBreakdownViewed(food: food.name, diet: diet.rawValue)
        guard let base = try? remoteDatabase.getFood(String(food.fdcId)),
              let serving = try? base.applyingPortion(Portion(amount: 1, gramWeight: food.gramWeight))
        else { return }

        let nutrients = serving.nutrientGroups.flatMap(\.nutrients)
        var amounts: [String: Double] = [:]
        var byNumber: [String: Nutrient] = [:]
        for nutrient in nutrients {
            amounts[nutrient.fdcNumber, default: 0] += nutrient.amount
            byNumber[nutrient.fdcNumber] = nutrient
        }
        let result = FoodBreakdown.make(
            amounts: amounts,
            goal: { fdcNumber in
                // A nutrient the food doesn't list (vitamin C in steak) still needs its unit.
                guard let nutrient = byNumber[fdcNumber] ?? remoteDatabase.getNutrient(withId: fdcNumber),
                      let rdi = NutrientGoalDefaults.effectiveRdi(
                        for: fdcNumber,
                        user: OnboardingDemoDashboardView.referenceUser,
                        rdiLibrary: rdiLibrary
                      )
                else { return nil }
                // Goals and foods can use different units (mg vs µg).
                return rdi.convertedTo(WeightUnit.unitFrom(nutrient)).recommendedAmount
            },
            micronutrients: Self.micronutrients,
            gaps: diet.micronutrientGaps
        )
        withAnimation(.snappy) {
            selected = food
            breakdown = result
            calories = amounts[FdcNutrientGroupMapper.NutrientNumber_Energy_KCal]
        }
    }

    private func name(_ fdcNumber: String) -> String {
        FdcNutrientGroupMapper.nutrientDisplayNames[fdcNumber]
            ?? remoteDatabase.getNutrient(withId: fdcNumber)?.name
            ?? fdcNumber
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Text("Tap a food you eat")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 24)

                    Text("See everything in one serving, not just the calories.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    FoodChoices()
                        .padding(.horizontal, 24)

                    if let selected, let breakdown {
                        BreakdownCard(food: selected, breakdown: breakdown)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.bottom, 24)
            }
            .readableContentWidth()

            LogActionButton(
                title: selected == nil ? "Tap a food above" : "Now see a full day",
                detail: selected == nil ? nil : "A sample \(diet == .balanced ? "" : diet.label.lowercased() + " ")day, scored",
                isEnabled: selected != nil,
                action: onContinue
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder private func FoodChoices() -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(diet.breakdownFoods) { food in
                let isSelected = food == selected
                Button {
                    select(food)
                } label: {
                    VStack(spacing: 2) {
                        Text(food.name)
                            .font(.headline)
                        Text(food.serving)
                            .font(.footnote)
                            .opacity(isSelected ? 0.9 : 0.6)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private func BreakdownCard(food: OnboardingBreakdownFood, breakdown: FoodBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(food.name), \(food.serving)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(breakdown.nutrientCount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("nutrients")
                        .font(.title3.bold())
                }
                Text("Most trackers show 4: calories, protein, carbs and fat.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !breakdown.richIn.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    LogFieldLabel("Rich in")
                    ForEach(breakdown.richIn, id: \.fdcNumber) { item in
                        PercentRow(name: name(item.fdcNumber), percent: item.percentOfGoal, color: .green)
                    }
                }
            }

            if !breakdown.lowIn.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    LogFieldLabel("Barely any")
                    ForEach(breakdown.lowIn, id: \.fdcNumber) { item in
                        PercentRow(name: name(item.fdcNumber), percent: item.percentOfGoal, color: .red)
                    }
                    if let gapPhrase = diet.gapPhrase {
                        Text("These run short \(gapPhrase). Logging shows whether the rest of your day makes up for them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .inCard(backgroundColor: Color.gray)
        .id(food)
    }

    /// Share of the daily goal, as a bar that tops out at 100%.
    @ViewBuilder private func PercentRow(name: String, percent: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 8)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    Capsule().fill(color)
                        .frame(width: max(4, proxy.size.width * min(percent, 1)))
                }
            }
            .frame(width: 110, height: 6)
            // Truncated like the dashboard, so 4.6% doesn't read as 5%.
            Text("\(Int(percent * 100))%")
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(color)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        OnboardingFoodBreakdownView(diet: .carnivore, onContinue: {})
    }
}
