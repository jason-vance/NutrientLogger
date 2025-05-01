//
//  DashboardNutrientSections.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI

//TODO: RELEASE: Consolidate sections, make this more screenshotable
//  Like, a proximates section that has
//      prominent calories
//      highlighted carbs, protein, fat
//      footnote, water, ash, alcohol (if present)
//      Is a navigationLink to ProximatesView that has all of the data
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
