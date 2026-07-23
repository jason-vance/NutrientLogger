//
//  OnboardingDemoDashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Onboarding step that shows a pre-populated sample day — built from real bundled-FDC foods that
/// fit the user's chosen diet — using the same dashboard section views the live app uses. Because
/// the personalization step already reordered the Nutrition tab, the diet's promoted "gap" nutrients
/// appear pinned to the top of each group, and their genuinely-low values land the "this is what
/// logging will show you" moment. Read-only.
struct OnboardingDemoDashboardView: View {

    let diet: NutritionDietPreset
    let onContinue: () -> Void

    @Inject private var remoteDatabase: RemoteDatabase

    /// A sexless ~30-year-old adult used only to resolve reference RDIs for the demo, so percentages
    /// show even though the onboarding user hasn't entered a profile yet. `.unknown` sex matches any
    /// life-stage entry (see `LifeStageNutrientRdi.matches`), so no sex is assumed. Never persisted.
    private static let referenceUser = User(
        gender: .unknown,
        birthdate: SimpleDate(year: 1995, month: 6, day: 15)
    )

    @State private var foods: [FoodItem]?
    @State private var meals: [DashboardMealList.Meal] = []
    @State private var consumedFoods: [ConsumedFood] = []

    private func loadFoods() {
        Task {
            var loadedFoods: [FoodItem] = []
            var consumed: [ConsumedFood] = []

            for demo in diet.demoDay {
                let portion = Portion(amount: 1, gramWeight: demo.gramWeight)
                guard let base = try? remoteDatabase.getFood(String(demo.fdcId)),
                      var food = try? base.applyingPortion(portion) else { continue }
                food.mealTime = demo.mealTime
                food.dateLogged = .today
                loadedFoods.append(food)
                // In-memory only (never inserted into a SwiftData context) — just to drive the
                // existing DashboardMealList / DashboardMealRow meal UI.
                consumed.append(ConsumedFood(
                    fdcId: demo.fdcId,
                    name: food.name,
                    portionAmount: portion.amount,
                    portionGramWeight: portion.gramWeight,
                    portionName: portion.name,
                    dateLogged: .today,
                    mealTime: demo.mealTime
                ))
            }

            // Only meals that actually have food — a sample day shouldn't show empty snack rows.
            let mealList = DashboardMealList.from(consumed).filter { !$0.foods.isEmpty }
            await MainActor.run {
                foods = loadedFoods
                meals = mealList
                consumedFoods = consumed
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Here's a day on your plan")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                Text("A sample day scored against your targets. The nutrients we're watching for you are pinned to the top — see which ones run low.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            .padding(.bottom, 16)

            Group {
                if let foods, !foods.isEmpty {
                    DashboardContent(foods: foods)
                } else if foods == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Fetch produced nothing (e.g. database hiccup) — don't trap the user here.
                    ContentUnavailableView(
                        "Ready to start",
                        systemImage: "fork.knife",
                        description: Text("Log your first food and your dashboard fills in just like this.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        .onAppear(perform: loadFoods)
    }

    @ViewBuilder private func DashboardContent(foods: [FoodItem]) -> some View {
        let aggregator = NutrientDataAggregator(foods)
        ScrollView {
            VStack(spacing: 2 * .spacingDefault) {
                DashboardMacrosSection(date: .today, aggregator: aggregator)
                MealsSection()
                DashboardWeeklyNutrientWatchSection(
                    allConsumedFoods: consumedFoods,
                    date: .today,
                    userOverride: Self.referenceUser
                )
                DashboardVitaminsSection(aggregator: aggregator, userOverride: Self.referenceUser)
                DashboardMineralsSection(aggregator: aggregator, userOverride: Self.referenceUser)
                DashboardLipidsSection(aggregator: aggregator, userOverride: Self.referenceUser)
                DashboardAminoAcidsSection(aggregator: aggregator, userOverride: Self.referenceUser)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .mask(
            // Fade the top edge so content scrolls away cleanly under the header.
            LinearGradient(
                colors: [.clear, .black, .black],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.04)
            )
        )
    }

    // Mirrors the Meals section on the real dashboard so the sample day's foods are visible,
    // grouped by meal, using the same DashboardMealRow.
    @ViewBuilder private func MealsSection() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Meals")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    if index > 0 {
                        Divider()
                            .padding(.leading, 16)
                    }
                    DashboardMealRow(meal: meal, date: .today)
                }
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: .gray)
            .padding(.top, .spacingDefault)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        OnboardingDemoDashboardView(diet: .carnivore, onContinue: {})
    }
}
