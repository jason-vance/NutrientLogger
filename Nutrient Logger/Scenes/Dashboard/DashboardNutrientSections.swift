//
//  DashboardNutrientSections.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI

struct DashboardNutrientSections: View {
    
    private let foods: [FoodItem]
    private let aggregator: NutrientDataAggregator
    
    init(foods: [FoodItem]) {
        self.foods = foods
        self.aggregator = NutrientDataAggregator(foods)
    }
    
    var nutrientGroups: [NutrientGroup] {
        aggregator.nutrientGroups
    }
    
    var body: some View {
        VStack(spacing: 2 * .spacingDefault) {
            DashboardMacrosSection(aggregator: aggregator)
            DashboardVitaminsSection(aggregator: aggregator)
            DashboardMineralsSection(aggregator: aggregator)
            //TODO: RELEASE: Add lipids section for EPA, DHA, etc
        }
        .padding(.horizontal)
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    
    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!
    
    List {
        DashboardNutrientSections(foods: [food])
    }
    .listDefaultModifiers()
}
