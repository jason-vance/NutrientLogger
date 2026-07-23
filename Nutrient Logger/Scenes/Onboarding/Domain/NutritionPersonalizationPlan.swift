//
//  NutritionPersonalizationPlan.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// Pure translation of a diet + concern answer into the per-group nutrient ordering and visible
/// count to persist. No side effects — `NutritionPersonalizationApplier` writes the result.
///
/// For each group, the diet's and concern's promoted nutrients are unioned. Every promoted nutrient
/// is kept visible by raising the group's visible count to `max(defaultVisibleCount, promotedCount)`,
/// so the two answers never compete for the limited slots. Groups with nothing promoted are left
/// untouched (absent from both dictionaries) so their defaults are preserved.
struct NutritionPersonalizationPlan: Equatable {

    /// Full ordered nutrient IDs to persist per group: promoted nutrients first (in the order they
    /// were unioned), then the group's remaining default nutrients in their original order.
    let orderByGroup: [CustomizableNutrientGroup: [String]]

    /// Visible count to persist per group.
    let visibleCountByGroup: [CustomizableNutrientGroup: Int]

    /// Whether this plan changes anything (both answers were defaults ⇒ empty plan).
    var isEmpty: Bool { orderByGroup.isEmpty && visibleCountByGroup.isEmpty }

    /// - Parameters:
    ///   - diet: the user's diet answer.
    ///   - concern: the user's focus answer.
    ///   - defaultOrders: each group's default (curated) nutrient order, i.e. the section whitelist.
    ///     Promoted nutrients not present here are ignored, so we never surface an ID that isn't a
    ///     real, shown nutrient.
    static func make(
        diet: NutritionDietPreset,
        concern: NutritionConcern,
        defaultOrders: [CustomizableNutrientGroup: [String]]
    ) -> NutritionPersonalizationPlan {
        var orderByGroup: [CustomizableNutrientGroup: [String]] = [:]
        var visibleCountByGroup: [CustomizableNutrientGroup: Int] = [:]

        for group in CustomizableNutrientGroup.allCases {
            let defaults = defaultOrders[group] ?? []
            // Concern first, then diet — a health focus feels more personal than a diet label.
            // Order among promoted nutrients is cosmetic since all of them stay visible.
            let requested = orderedUnion(
                concern.promotedNutrients[group] ?? [],
                diet.promotedNutrients[group] ?? []
            )
            let promoted = requested.filter { defaults.contains($0) }
            guard !promoted.isEmpty else { continue }

            let remainder = defaults.filter { !promoted.contains($0) }
            orderByGroup[group] = promoted + remainder
            visibleCountByGroup[group] = max(CustomizableNutrientGroup.defaultVisibleCount, promoted.count)
        }

        return NutritionPersonalizationPlan(
            orderByGroup: orderByGroup,
            visibleCountByGroup: visibleCountByGroup
        )
    }

    /// Concatenates two lists preserving first-seen order and dropping duplicates.
    private static func orderedUnion(_ first: [String], _ second: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for id in first + second where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }
}
