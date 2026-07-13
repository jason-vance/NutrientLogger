//
//  GoalProgressBarLayout.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation

/// Pure layout math for `GoalProgressBar`: how much of the bar is solid vs. a dashed
/// "exceeded" segment. `goal` sizes the solid fill below `dashedThreshold`; `dashedThreshold`
/// is the point past which the bar switches to the split solid/dashed rendering (for macros
/// this is the same value as `goal`; for vitamins/minerals it's the upper limit, a separate,
/// higher threshold than the RDA-based `goal`).
struct GoalProgressBarLayout: Equatable {
    let solidFraction: Double
    let excessFraction: Double
    let isExceeded: Bool

    static func compute(amount: Double, goal: Double, dashedThreshold: Double?) -> GoalProgressBarLayout {
        if let dashedThreshold,
           dashedThreshold > 0,
           dashedThreshold < .greatestFiniteMagnitude,
           amount > dashedThreshold {
            return GoalProgressBarLayout(
                solidFraction: dashedThreshold / amount,
                excessFraction: (amount - dashedThreshold) / amount,
                isExceeded: true
            )
        }

        let fraction = goal > 0 ? min(amount / goal, 1.0) : 0
        return GoalProgressBarLayout(solidFraction: fraction, excessFraction: 0, isExceeded: false)
    }
}
