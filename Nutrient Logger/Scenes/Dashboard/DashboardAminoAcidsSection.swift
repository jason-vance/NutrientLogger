//
//  DashboardAminoAcidsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import SwiftUI

struct DashboardAminoAcidsSection: View {
    
    static let blacklist: Set<String> = []
    
    static let orderedWhitelist: [String] = []
    
    let aminoAcidsKey = FdcNutrientGroupMapper.GroupNumber_AminoAcids
    
    let aggregator: NutrientDataAggregator
    
    var body: some View {
        DashboardNutrientsSection(
            blacklist: Self.blacklist,
            orderedWhitelist: Self.orderedWhitelist,
            groupKey: aminoAcidsKey,
            headerText: "Amino Acids",
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
            DashboardAminoAcidsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
