//
//  NutritionPersonalizationApplier+Dashboard.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

extension NutritionPersonalizationApplier {

    /// The production applier, wired to `.standard` defaults and the live dashboard whitelists.
    /// Lives in its own file (app target only) so the testable core stays free of SwiftUI/View deps.
    static func standard() -> NutritionPersonalizationApplier {
        NutritionPersonalizationApplier(
            defaults: .standard,
            defaultOrders: [
                .vitamins: DashboardVitaminsSection.orderedWhitelist,
                .minerals: DashboardMineralsSection.orderedWhitelist,
                .lipids: DashboardLipidsSection.orderedWhitelist,
                .aminoAcids: DashboardAminoAcidsSection.orderedWhitelist,
            ]
        )
    }
}
