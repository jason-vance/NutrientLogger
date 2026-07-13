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
            DashboardVitaminsSection(aggregator: aggregator)
            DashboardMineralsSection(aggregator: aggregator)
            MealsSection()
            DashboardCarbsSection(aggregator: aggregator)
            DashboardLipidsSection(aggregator: aggregator)
            DashboardAminoAcidsSection(aggregator: aggregator)
        }
        .padding(.horizontal)
    }

    @ViewBuilder private func MealsSection() -> some View {
        let meals = DashboardMealList.from(consumedFoods)
            .sorted { $0.mealTime < $1.mealTime }

        if !meals.isEmpty {
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
                        DashboardMealRow(meal: meal, date: date)
                    }
                }
                .padding(.vertical, 4)
                .inCard(backgroundColor: .gray)
                .padding(.top, .spacingDefault)
            }
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
