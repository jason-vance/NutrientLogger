//
//  NutritionPersonalizationApplier.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// Writes a `NutritionPersonalizationPlan` to the same `UserDefaults`-backed keys the Nutrition-tab
/// dashboard sections read (`@AppStorage`). It only fills in a group the user hasn't already
/// customized, so re-running (or a later manual arrangement) is never clobbered.
struct NutritionPersonalizationApplier {

    let defaults: UserDefaults

    /// Each group's default (curated) nutrient order — the section whitelists in production.
    let defaultOrders: [CustomizableNutrientGroup: [String]]

    func apply(diet: NutritionDietPreset, concern: NutritionConcern) {
        let plan = NutritionPersonalizationPlan.make(
            diet: diet,
            concern: concern,
            defaultOrders: defaultOrders
        )

        for group in CustomizableNutrientGroup.allCases {
            guard let order = plan.orderByGroup[group] else { continue }

            // Respect an existing arrangement: only write a group whose order is still at its default.
            let existingOrder = defaults.string(forKey: group.orderStorageKey) ?? ""
            guard existingOrder.isEmpty else { continue }

            defaults.set(order.joined(separator: ","), forKey: group.orderStorageKey)
            if let count = plan.visibleCountByGroup[group] {
                defaults.set(count, forKey: group.visibleCountStorageKey)
            }
        }
    }
}
