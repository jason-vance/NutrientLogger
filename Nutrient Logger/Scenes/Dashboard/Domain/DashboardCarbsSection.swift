//
//  DashboardCarbsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import SwiftUI

struct DashboardCarbsSection: View {
    
    static let blacklist: Set<String> = [
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_BySummation,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary_AOAC,
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_Other,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalNLEA,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_Added,
        
    ]
    
    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalIncludingNLEA,
    ]
    
    let carbsKey = FdcNutrientGroupMapper.GroupNumber_Carbohydrates
    
    let aggregator: NutrientDataAggregator
    
    var body: some View {
        DashboardNutrientsSection(
            blacklist: Self.blacklist,
            orderedWhitelist: Self.orderedWhitelist,
            groupKey: carbsKey,
            headerText: "Carbohydrates",
            aggregator: aggregator
        )
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {UsdaNutrientRdiLibrary.create()}
    let _ = swinjectContainer.autoregister(UserService.self) {MockUserService(currentUser: .sample)}

    let sampleFoods = FoodItem.sampleFoods
    
    ScrollView {
        VStack {
            DashboardCarbsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
