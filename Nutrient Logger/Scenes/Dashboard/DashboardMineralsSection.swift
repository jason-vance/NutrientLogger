//
//  DashboardMineralsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

//TODO: Navigate to NutrientDetailView with all of the foods containing this nutrient
struct DashboardMineralsSection: View {
    
    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_Boron_B,
        FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
        FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr,
        FdcNutrientGroupMapper.NutrientNumber_Copper_Cu,
        FdcNutrientGroupMapper.NutrientNumber_Fluoride_F,
        FdcNutrientGroupMapper.NutrientNumber_Iodine_I,
        FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
        FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
        FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn,
        FdcNutrientGroupMapper.NutrientNumber_Molybdenum_Mo,
        FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P,
        FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
        FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
        FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
        FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
        FdcNutrientGroupMapper.NutrientNumber_Chlorine_Cl,
        FdcNutrientGroupMapper.NutrientNumber_Cobalt_Co,
        FdcNutrientGroupMapper.NutrientNumber_Nickel_Ni,
        FdcNutrientGroupMapper.NutrientNumber_Sulfur_S,
    ]
    
    let mineralsKey = FdcNutrientGroupMapper.GroupNumber_Minerals
    
    let aggregator: NutrientDataAggregator
    
    var body: some View {
        DashboardNutrientsSection(
            blacklist: [],
            orderedWhitelist: Self.orderedWhitelist,
            groupKey: mineralsKey,
            headerText: "Minerals",
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
            DashboardMineralsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
