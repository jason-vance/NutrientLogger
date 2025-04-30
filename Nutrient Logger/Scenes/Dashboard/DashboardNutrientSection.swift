//
//  DashboardNutrientSection.swift
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
    
    let columns: [GridItem] = Array(repeating: GridItem(.adaptive(minimum: 100)), count: 2)
    
    var body: some View {
        VStack {
            HStack {
                Text("My Nutrients")
                    .listSectionHeader()
                Spacer()
            }
            .padding(.top)
            VStack {
                ForEach(nutrientGroups) { nutrientGroup in
                    let nutrients = Nutrient.sortNutrients(nutrientGroup.nutrients)
                    let fdcNumbers = Set(nutrients.map(\.fdcNumber))
                    
                    HStack {
                        Text(nutrientGroup.name)
                            .listSubsectionHeader()
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    LazyVGrid(columns: columns) {
                        ForEach(fdcNumbers.sorted(), id: \.self) { fdcNumber in
                            DashboardNutrientCell(nutrients: aggregator.nutrientsByNutrientNumber[fdcNumber] ?? [])
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
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
