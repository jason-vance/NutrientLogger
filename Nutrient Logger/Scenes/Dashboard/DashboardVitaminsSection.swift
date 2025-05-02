//
//  DashboardVitaminsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

//TODO: Navigate to NutrientDetailView with all of the sub-nutrients and foods containing those nutrients
//  IE. Vitamin A screen has all Vitamin A's, Retinol, beta carotene, etc
struct DashboardVitaminsSection: View {
    
    static let blacklist: Set<String> = [
        FdcNutrientGroupMapper.NutrientNumber_Choline_Free,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphotidylCholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromGlycerophosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromSphingomyelin,
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU,
        FdcNutrientGroupMapper.NutrientNumber_Retinol,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Lutein,
        FdcNutrientGroupMapper.NutrientNumber_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lutein_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Added,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_LabelEntryPrimarily,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Delta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Delta,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Menaquinone_4,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Dihydrophylloquinone,
        FdcNutrientGroupMapper.NutrientNumber_FolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylFolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylTetrahyrdofolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Total,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Food,
        FdcNutrientGroupMapper.NutrientNumber_MethylTetrahydrofolate,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD3_Cholecalciferol,
        FdcNutrientGroupMapper.NutrientNumber_Hydroxycholecalciferol,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12_Added
    ]
    
    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
        FdcNutrientGroupMapper.NutrientNumber_Thiamin,
        FdcNutrientGroupMapper.NutrientNumber_Riboflavin,
        FdcNutrientGroupMapper.NutrientNumber_Niacin,
        FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB6,
        FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
        FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone,
        FdcNutrientGroupMapper.NutrientNumber_Choline_Total,
//        FdcNutrientGroupMapper.NutrientNumber_Betaine,
//        FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha,
//        FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta,
//        FdcNutrientGroupMapper.NutrientNumber_Caffeine,
//        FdcNutrientGroupMapper.NutrientNumber_Lycopene,
//        FdcNutrientGroupMapper.NutrientNumber_Lutein_Zeaxanthin,
//        FdcNutrientGroupMapper.NutrientNumber_Theobromine,
//        FdcNutrientGroupMapper.NutrientNumber_Biotin, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Phytoene, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Phytofluene, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Epigallocatechin3Gallate // Nothing in the database has this in it
    ]
    
    let vitaminsKey = FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents
    
    let aggregator: NutrientDataAggregator
    
    var body: some View {
        DashboardNutrientsSection(
            blacklist: Self.blacklist,
            orderedWhitelist: Self.orderedWhitelist,
            groupKey: vitaminsKey,
            headerText: "Vitamins",
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
            DashboardVitaminsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
