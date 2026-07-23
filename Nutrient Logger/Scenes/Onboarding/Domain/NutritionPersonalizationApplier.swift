//
//  NutritionPersonalizationApplier.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// Writes a `NutritionPersonalizationPlan` to the same `UserDefaults`-backed keys the Nutrition-tab
/// dashboard sections read (`@AppStorage`).
struct NutritionPersonalizationApplier {

    let defaults: UserDefaults

    /// Each group's default (curated) nutrient order — the section whitelists in production.
    let defaultOrders: [CustomizableNutrientGroup: [String]]

    /// - Parameter replacingExisting: pass `true` from onboarding, which is the authoritative source
    ///   of the ordering (the user has no manual customization to protect yet). Every group is
    ///   rewritten to reflect exactly this selection — promoted groups overwritten, groups the
    ///   selection no longer promotes reset to default — so changing the answer and re-applying fully
    ///   updates. Pass `false` (default) to only fill groups the user hasn't customized and never
    ///   clobber an existing arrangement.
    func apply(diet: NutritionDietPreset, concern: NutritionConcern, replacingExisting: Bool = false) {
        let plan = NutritionPersonalizationPlan.make(
            diet: diet,
            concern: concern,
            defaultOrders: defaultOrders
        )

        for group in CustomizableNutrientGroup.allCases {
            guard let order = plan.orderByGroup[group],
                  let count = plan.visibleCountByGroup[group] else {
                // Group isn't promoted by this selection. When replacing, clear any prior
                // application so a previously-promoted group returns to its default order.
                if replacingExisting {
                    defaults.removeObject(forKey: group.orderStorageKey)
                    defaults.removeObject(forKey: group.visibleCountStorageKey)
                }
                continue
            }

            if !replacingExisting {
                // Respect an existing arrangement: only write a group still at its default.
                let existingOrder = defaults.string(forKey: group.orderStorageKey) ?? ""
                guard existingOrder.isEmpty else { continue }
            }

            defaults.set(order.joined(separator: ","), forKey: group.orderStorageKey)
            defaults.set(count, forKey: group.visibleCountStorageKey)
        }
    }
}
