//
//  DashboardNutrientSections.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI

struct DashboardNutrientSections: View {

    private let date: SimpleDate
    private let foods: [FoodItem]
    private let consumedFoods: [ConsumedFood]
    private let allConsumedFoods: [ConsumedFood]
    private let aggregator: NutrientDataAggregator

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataController: DataController
    @Inject private var engagementAnalytics: EngagementAnalytics

    init(date: SimpleDate, foods: [FoodItem], consumedFoods: [ConsumedFood], allConsumedFoods: [ConsumedFood]) {
        self.date = date
        self.foods = foods
        self.consumedFoods = consumedFoods
        self.allConsumedFoods = allConsumedFoods
        self.aggregator = NutrientDataAggregator(foods)
    }

    var nutrientGroups: [NutrientGroup] {
        aggregator.nutrientGroups
    }

    var body: some View {
        VStack(spacing: 2 * .spacingDefault) {
            DashboardMacrosSection(date: date, aggregator: aggregator)
            DashboardWeeklyNutrientWatchSection(allConsumedFoods: allConsumedFoods, date: date)
                .id(ScreenshotScene.weeklyWatchId)
            MealsSection()
            DashboardVitaminsSection(aggregator: aggregator)
                .id(ScreenshotScene.vitaminsId)
            DashboardMineralsSection(aggregator: aggregator)
            DashboardCarbsSection(aggregator: aggregator)
            DashboardLipidsSection(aggregator: aggregator)
            DashboardAminoAcidsSection(aggregator: aggregator)
        }
        .padding(.horizontal)
    }

    private func repeatMeal(_ previous: MealRepeat.Previous) {
        for food in MealRepeat.copies(of: previous.foods, to: date) {
            modelContext.insert(food)
        }
        try? modelContext.save()
        engagementAnalytics.mealRepeated(foodCount: previous.foods.count, daysBack: previous.daysBack)
        dataController.updateDailySummary()
    }

    @ViewBuilder private func MealsSection() -> some View {
        // DashboardMealList.from always returns every valid meal time (empty ones included), so
        // this section stays visible as a logging entry point even on a day with nothing logged.
        let meals = DashboardMealList.from(consumedFoods)

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
                    let previous = date <= .today && meal.foods.isEmpty
                        ? MealRepeat.previous(meal.mealTime, before: date, in: allConsumedFoods)
                        : nil
                    DashboardMealRow(
                        meal: meal,
                        date: date,
                        repeatLabel: previous.map { MealRepeat.label(for: $0, mealTime: meal.mealTime, selectedDate: date) },
                        onRepeat: previous.map { previous in { repeatMeal(previous) } }
                    )
                }
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: .gray)
            .padding(.top, .spacingDefault)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }

    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!

    ScrollView {
        DashboardNutrientSections(date: .today, foods: [food], consumedFoods: [.dashboardSample], allConsumedFoods: [.dashboardSample])
    }
}
