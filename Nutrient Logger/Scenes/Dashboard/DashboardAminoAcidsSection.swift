//
//  DashboardAminoAcidsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import SwiftUI

struct DashboardAminoAcidsSection: View {

    static let blacklist: Set<String> = []

    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_Tryptophan,
        FdcNutrientGroupMapper.NutrientNumber_Threonine,
        FdcNutrientGroupMapper.NutrientNumber_Isoleucine,
        FdcNutrientGroupMapper.NutrientNumber_Leucine,
        FdcNutrientGroupMapper.NutrientNumber_Lysine,
        FdcNutrientGroupMapper.NutrientNumber_Methionine,
        FdcNutrientGroupMapper.NutrientNumber_Cystine,
        FdcNutrientGroupMapper.NutrientNumber_Phenylalanine,
        FdcNutrientGroupMapper.NutrientNumber_Tyrosine,
        FdcNutrientGroupMapper.NutrientNumber_Valine,
        FdcNutrientGroupMapper.NutrientNumber_Arginine,
        FdcNutrientGroupMapper.NutrientNumber_Histidine,
        FdcNutrientGroupMapper.NutrientNumber_Alanine,
        FdcNutrientGroupMapper.NutrientNumber_AsparticAcid,
        FdcNutrientGroupMapper.NutrientNumber_GlutamicAcid,
        FdcNutrientGroupMapper.NutrientNumber_Glycine,
        FdcNutrientGroupMapper.NutrientNumber_Proline,
        FdcNutrientGroupMapper.NutrientNumber_Serine,
        FdcNutrientGroupMapper.NutrientNumber_Hydroxyproline,
        FdcNutrientGroupMapper.NutrientNumber_Cysteine,
        FdcNutrientGroupMapper.NutrientNumber_Glutamine,
        FdcNutrientGroupMapper.NutrientNumber_Taurine,
    ]

    @AppStorage("nutrientCustomize_aminoAcids_order") private var orderRaw: String = ""
    @AppStorage("nutrientCustomize_aminoAcids_hidden") private var hiddenRaw: String = ""
    @AppStorage("nutrientCustomize_aminoAcids_visibleCount") private var visibleCount: Int = 3

    let aminoAcidsKey = FdcNutrientGroupMapper.GroupNumber_AminoAcids

    let aggregator: NutrientDataAggregator

    private var effectiveOrder: [String] {
        if orderRaw.isEmpty { return Self.orderedWhitelist }
        return orderRaw.split(separator: ",").map(String.init)
    }

    private var hiddenSet: Set<String> {
        Set(hiddenRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    var body: some View {
        DashboardNutrientsSection(
            blacklist: Self.blacklist.union(hiddenSet),
            orderedWhitelist: effectiveOrder.filter { !hiddenSet.contains($0) },
            groupKey: aminoAcidsKey,
            headerText: "Amino Acids",
            aggregator: aggregator,
            previewCount: visibleCount
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
