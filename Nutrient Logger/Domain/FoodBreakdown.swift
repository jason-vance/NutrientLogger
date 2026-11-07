//
//  FoodBreakdown.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/7/26.
//

import Foundation

/// What one serving of a food holds, for the onboarding "tap a food" step: how many nutrients it
/// reports, the vitamins and minerals it's richest in, and which of the diet's usual gaps it barely
/// touches. Percentages are of the daily goal (1 = 100%).
struct FoodBreakdown: Equatable {

    struct Item: Equatable {
        let fdcNumber: String
        let percentOfGoal: Double
    }

    /// Nutrients with a reported amount above zero.
    let nutrientCount: Int
    /// The highest share of the daily goal first, each at least `richThreshold`.
    let richIn: [Item]
    /// The diet's gap nutrients that this serving covers less than `lowThreshold` of, in the
    /// order the diet lists them.
    let lowIn: [Item]

    /// A serving that covers this much of a goal counts as a good source.
    static let richThreshold = 0.1
    /// A gap nutrient under this share of its goal reads as missing from the food.
    static let lowThreshold = 0.05

    /// - Parameters:
    ///   - amounts: Per-serving amount by nutrient number, in the food's own units.
    ///   - goal: The daily goal for a nutrient number, in the same unit as `amounts`. Nil when it
    ///     has none.
    ///   - micronutrients: The vitamins and minerals worth ranking. Others (macros, amino acids)
    ///     only count toward `nutrientCount`.
    ///   - gaps: The diet's usual short nutrients.
    ///   - richCount: The most `richIn` items to keep.
    static func make(
        amounts: [String: Double],
        goal: (String) -> Double?,
        micronutrients: [String],
        gaps: [String],
        richCount: Int = 6
    ) -> FoodBreakdown {
        func percent(_ fdcNumber: String) -> Double? {
            guard let goal = goal(fdcNumber), goal > 0 else { return nil }
            return (amounts[fdcNumber] ?? 0) / goal
        }

        let gapSet = Set(gaps)
        let rich = micronutrients
            .filter { !gapSet.contains($0) }
            .compactMap { fdcNumber in percent(fdcNumber).map { Item(fdcNumber: fdcNumber, percentOfGoal: $0) } }
            .filter { $0.percentOfGoal >= richThreshold }
            // Stable order for equal shares, so the list doesn't shuffle between runs.
            .enumerated()
            .sorted { $0.element.percentOfGoal != $1.element.percentOfGoal
                ? $0.element.percentOfGoal > $1.element.percentOfGoal
                : $0.offset < $1.offset }
            .map(\.element)

        let low = gaps
            .compactMap { fdcNumber in percent(fdcNumber).map { Item(fdcNumber: fdcNumber, percentOfGoal: $0) } }
            .filter { $0.percentOfGoal < lowThreshold }

        return FoodBreakdown(
            nutrientCount: amounts.values.filter { $0 > 0 }.count,
            richIn: Array(rich.prefix(richCount)),
            lowIn: low
        )
    }
}
