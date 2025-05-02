//
//  DashboardLipidsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/1/25.
//

import SwiftUI

struct DashboardLipidsSection: View {
    
    static let blacklist: Set<String> = [
        FdcNutrientGroupMapper.NutrientNumber_4_0,
        FdcNutrientGroupMapper.NutrientNumber_5_0,
        FdcNutrientGroupMapper.NutrientNumber_6_0,
        FdcNutrientGroupMapper.NutrientNumber_7_0,
        FdcNutrientGroupMapper.NutrientNumber_8_0,
        FdcNutrientGroupMapper.NutrientNumber_9_0,
        FdcNutrientGroupMapper.NutrientNumber_10_0,
        FdcNutrientGroupMapper.NutrientNumber_11_0,
        FdcNutrientGroupMapper.NutrientNumber_12_0,
        FdcNutrientGroupMapper.NutrientNumber_13_0,
        FdcNutrientGroupMapper.NutrientNumber_14_0,
        FdcNutrientGroupMapper.NutrientNumber_15_0,
        FdcNutrientGroupMapper.NutrientNumber_16_0,
        FdcNutrientGroupMapper.NutrientNumber_17_0,
        FdcNutrientGroupMapper.NutrientNumber_18_0,
        FdcNutrientGroupMapper.NutrientNumber_20_0,
        FdcNutrientGroupMapper.NutrientNumber_21_0,
        FdcNutrientGroupMapper.NutrientNumber_22_0,
        FdcNutrientGroupMapper.NutrientNumber_23_0,
        FdcNutrientGroupMapper.NutrientNumber_24_0,
        FdcNutrientGroupMapper.NutrientNumber_12_1,
        FdcNutrientGroupMapper.NutrientNumber_14_1,
        FdcNutrientGroupMapper.NutrientNumber_14_1_T,
        FdcNutrientGroupMapper.NutrientNumber_14_1_C,
        FdcNutrientGroupMapper.NutrientNumber_15_1,
        FdcNutrientGroupMapper.NutrientNumber_16_1,
        FdcNutrientGroupMapper.NutrientNumber_16_1_C,
        FdcNutrientGroupMapper.NutrientNumber_17_1,
        FdcNutrientGroupMapper.NutrientNumber_17_1_C,
        FdcNutrientGroupMapper.NutrientNumber_18_1,
        FdcNutrientGroupMapper.NutrientNumber_18_1_C,
        FdcNutrientGroupMapper.NutrientNumber_18_1_11_t_18_1t_n_7,
        FdcNutrientGroupMapper.NutrientNumber_20_1,
        FdcNutrientGroupMapper.NutrientNumber_20_1_C,
        FdcNutrientGroupMapper.NutrientNumber_20_1_T,
        FdcNutrientGroupMapper.NutrientNumber_22_1,
        FdcNutrientGroupMapper.NutrientNumber_22_1_C,
        FdcNutrientGroupMapper.NutrientNumber_22_1_N_9,
        FdcNutrientGroupMapper.NutrientNumber_22_1_N_11,
        FdcNutrientGroupMapper.NutrientNumber_24_1_C,
        FdcNutrientGroupMapper.NutrientNumber_18_2,
        FdcNutrientGroupMapper.NutrientNumber_18_2_I,
        FdcNutrientGroupMapper.NutrientNumber_18_2_C,
        FdcNutrientGroupMapper.NutrientNumber_18_2_N_6_C_C,
        FdcNutrientGroupMapper.NutrientNumber_18_2_CLAs,
        FdcNutrientGroupMapper.NutrientNumber_18_3,
        FdcNutrientGroupMapper.NutrientNumber_18_3_C,
        FdcNutrientGroupMapper.NutrientNumber_18_3_T,
        FdcNutrientGroupMapper.NutrientNumber_18_3_I,
        FdcNutrientGroupMapper.NutrientNumber_18_3_N_6_C_C_C,
        FdcNutrientGroupMapper.NutrientNumber_18_4,
        FdcNutrientGroupMapper.NutrientNumber_20_2_C,
        FdcNutrientGroupMapper.NutrientNumber_20_2_N_6_C_C,
        FdcNutrientGroupMapper.NutrientNumber_20_3,
        FdcNutrientGroupMapper.NutrientNumber_20_3_C,
        FdcNutrientGroupMapper.NutrientNumber_20_3_N_3,
        FdcNutrientGroupMapper.NutrientNumber_20_3_N_6,
        FdcNutrientGroupMapper.NutrientNumber_20_3_N_9,
        FdcNutrientGroupMapper.NutrientNumber_20_4,
        FdcNutrientGroupMapper.NutrientNumber_20_4_C,
        FdcNutrientGroupMapper.NutrientNumber_20_4_N_6,
        FdcNutrientGroupMapper.NutrientNumber_20_5_C,
        FdcNutrientGroupMapper.NutrientNumber_21_5,
        FdcNutrientGroupMapper.NutrientNumber_22_2,
        FdcNutrientGroupMapper.NutrientNumber_22_3,
        FdcNutrientGroupMapper.NutrientNumber_22_4,
        FdcNutrientGroupMapper.NutrientNumber_22_5_C,
        FdcNutrientGroupMapper.NutrientNumber_22_6_C,
        FdcNutrientGroupMapper.NutrientNumber_16_1_T,
        FdcNutrientGroupMapper.NutrientNumber_18_1_T,
        FdcNutrientGroupMapper.NutrientNumber_22_1_T,
        FdcNutrientGroupMapper.NutrientNumber_18_2_T_NotFurtherDefined,
        FdcNutrientGroupMapper.NutrientNumber_18_2_T_T
    ]
    
    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalSaturated,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalMonounsaturated,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalPolyunsaturated,
        FdcNutrientGroupMapper.NutrientNumber_Cholesterol,
        FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
        FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
        FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA,
        FdcNutrientGroupMapper.NutrientNumber_22_5_N_3_DPA
    ]
    
    let lipidsKey = FdcNutrientGroupMapper.GroupNumber_Lipids
    
    let aggregator: NutrientDataAggregator
    
    var body: some View {
        DashboardNutrientsSection(
            blacklist: Self.blacklist,
            orderedWhitelist: Self.orderedWhitelist,
            groupKey: lipidsKey,
            headerText: "Lipids",
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
            DashboardLipidsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
