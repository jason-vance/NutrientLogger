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
    private let aggregator: NutrientDataAggregator
    
    init(date: SimpleDate, foods: [FoodItem]) {
        self.date = date
        self.foods = foods
        self.aggregator = NutrientDataAggregator(foods)
    }
    
    var nutrientGroups: [NutrientGroup] {
        aggregator.nutrientGroups
    }
    
    var body: some View {
        VStack(spacing: 2 * .spacingDefault) {
            DashboardMacrosSection(date: date, aggregator: aggregator)
            DashboardVitaminsSection(aggregator: aggregator)
            DashboardMineralsSection(aggregator: aggregator)
            DashboardCarbsSection(aggregator: aggregator)
            DashboardLipidsSection(aggregator: aggregator)
            DashboardAminoAcidsSection(aggregator: aggregator)
        }
        .padding(.horizontal)
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    
    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!
    
    List {
        DashboardNutrientSections(date: .today, foods: [food])
    }
    .listDefaultModifiers()
}
