//
//  NutrientBalanceCalculator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/17/26.
//

import Foundation

struct NutrientBalanceResult: Equatable, Identifiable {
    let id: String
    let name: String
    let explanation: String
    let targetText: String
    /// The measured ratio (numerator ÷ denominator).
    let ratio: Double
    /// True when the ratio is above the healthy maximum.
    let isTooHigh: Bool
    /// True when the ratio is below the healthy minimum.
    let isTooLow: Bool
    /// How far outside the band the ratio sits (1.0 = right at the edge, larger = worse). Used for
    /// ranking the most out-of-balance nutrients first.
    let severity: Double

    /// Compact "2.3 : 1" form for chips.
    var ratioText: String { "\(ratio.formatted(maxDigits: 1)) : 1" }
}

enum NutrientBalanceCalculator {

    /// Evaluates one ratio against summed intake amounts, expressed in a common unit (grams), per
    /// nutrient. Both sides are summed so a balance can span several nutrients (e.g. omega-6 is
    /// linoleic + arachidonic). Returns nil when there isn't enough data to form the ratio (no
    /// numerator or no denominator intake), or when the ratio sits inside its healthy band.
    static func evaluate(ratio: NutrientRatio, gramsByNutrient: [String: Double]) -> NutrientBalanceResult? {
        let numerator = ratio.numeratorNutrientIds.reduce(0.0) { $0 + (gramsByNutrient[$1] ?? 0) }
        let denominator = ratio.denominatorNutrientIds.reduce(0.0) { $0 + (gramsByNutrient[$1] ?? 0) }
        guard numerator > 0, denominator > 0 else { return nil }

        let value = numerator / denominator
        let tooHigh = ratio.healthyMax.map { value > $0 } ?? false
        let tooLow = ratio.healthyMin.map { value < $0 } ?? false
        guard tooHigh || tooLow else { return nil }

        let severity: Double
        if tooHigh, let max = ratio.healthyMax {
            severity = value / max
        } else if tooLow, let min = ratio.healthyMin, value > 0 {
            severity = min / value
        } else {
            severity = 1
        }

        return NutrientBalanceResult(
            id: ratio.id,
            name: ratio.name,
            explanation: ratio.explanation,
            targetText: ratio.targetText,
            ratio: value,
            isTooHigh: tooHigh,
            isTooLow: tooLow,
            severity: severity
        )
    }
}
