//
//  DashboardNutrientSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI

struct DashboardNutrientSection: View {
    
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

        Section {
            ForEach(nutrientGroups) { nutrientGroup in
                let nutrients = Nutrient.sortNutrients(nutrientGroup.nutrients)
                let fdcNumbers = Set(nutrients.map(\.fdcNumber))
                
                Text(nutrientGroup.name)
                    .listSubsectionHeader()
                ForEach(fdcNumbers.sorted(), id: \.self) { fdcNumber in
                    DashboardNutrientRow(nutrients: aggregator.nutrientsByNutrientNumber[fdcNumber] ?? [])
                }
            }
        } header: {
            Text("My Nutrients")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    
    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!
    
    List {
        DashboardNutrientSection(foods: [food])
    }
    .listDefaultModifiers()
}
