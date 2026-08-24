//
//  NutrientBalanceContributors.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 8/24/26.
//

import Foundation

/// One food's contribution to a side of a nutrient balance, summed over the watch card's
/// lookback window.
struct NutrientContribution: Identifiable, Equatable {
    var id: String { foodName }
    let foodName: String
    /// Total contributed across the window, in grams — the common unit balances are computed in.
    let grams: Double
    /// Fraction of the side's total this food accounts for, 0...1.
    let share: Double

    var amountText: String { NutrientContribution.format(grams: grams) }

    var shareText: String { "\((share * 100).formatted(maxDigits: 0))%" }

    /// Balances span nutrients whose natural units differ by orders of magnitude (grams of
    /// linoleic acid, milligrams of sodium), so the unit comes from the amount rather than
    /// always showing raw grams.
    static func format(grams: Double) -> String {
        if grams >= 1 { return "\(grams.formatted(maxDigits: 1)) g" }
        if grams >= 0.001 { return "\((grams * 1_000).formatted(maxDigits: 1)) mg" }
        return "\((grams * 1_000_000).formatted(maxDigits: 0)) \u{00B5}g"
    }
}

/// The foods driving each side of an out-of-balance ratio.
struct BalanceContributions: Equatable {
    let numerator: [NutrientContribution]
    let denominator: [NutrientContribution]

    var isEmpty: Bool { numerator.isEmpty && denominator.isEmpty }

    static let empty = BalanceContributions(numerator: [], denominator: [])
}

enum NutrientBalanceContributors {

    static let maxFoodsPerSide = 5

    /// Ranks the foods behind one side of a balance, largest contributor first.
    /// `gramsByNutrientAndFood` maps nutrient id -> food name -> grams contributed across the
    /// window. A food appearing under several of the side's nutrients (a fish contributing both
    /// EPA and DHA, say) is summed into a single entry.
    static func topFoods(
        nutrientIds: [String],
        gramsByNutrientAndFood: [String: [String: Double]],
        limit: Int = maxFoodsPerSide
    ) -> [NutrientContribution] {
        var gramsByFood: [String: Double] = [:]
        for nutrientId in nutrientIds {
            for (foodName, grams) in gramsByNutrientAndFood[nutrientId] ?? [:] where grams > 0 {
                gramsByFood[foodName, default: 0] += grams
            }
        }

        let total = gramsByFood.values.reduce(0, +)
        guard total > 0 else { return [] }

        return gramsByFood
            .sorted { lhs, rhs in
                // Ties break on name so the list doesn't reshuffle between recomputes.
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(limit)
            .map { NutrientContribution(foodName: $0.key, grams: $0.value, share: $0.value / total) }
    }

    static func contributions(
        for ratio: NutrientRatio,
        gramsByNutrientAndFood: [String: [String: Double]]
    ) -> BalanceContributions {
        BalanceContributions(
            numerator: topFoods(
                nutrientIds: ratio.numeratorNutrientIds,
                gramsByNutrientAndFood: gramsByNutrientAndFood
            ),
            denominator: topFoods(
                nutrientIds: ratio.denominatorNutrientIds,
                gramsByNutrientAndFood: gramsByNutrientAndFood
            )
        )
    }
}
