//
//  GoalProgressBar.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/13/26.
//

import SwiftUI

/// A linear version of `CalorieGoalRing`'s exceeded-goal treatment: a solid fill up to
/// `dashedThreshold`, then a translucent dashed segment for the amount beyond it.
struct GoalProgressBar: View {

    let amount: Double
    let goal: Double
    let dashedThreshold: Double?
    let fillColor: Color
    let exceededFillColor: Color
    let exceededOutlineColor: Color
    var height: CGFloat = 6
    var gap: CGFloat = 2

    private var layout: GoalProgressBarLayout {
        .compute(amount: amount, goal: goal, dashedThreshold: dashedThreshold)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.2))

                if layout.isExceeded {
                    HStack(spacing: gap) {
                        Capsule()
                            .fill(fillColor.gradient)
                            .frame(width: max(width * layout.solidFraction - gap / 2, 0))
                        ZStack {
                            Capsule().fill(exceededFillColor)
                            Capsule()
                                .stroke(exceededOutlineColor, style: StrokeStyle(lineWidth: 1, dash: [1.5, 1.5]))
                        }
                        .frame(width: max(width * layout.excessFraction - gap / 2, 0))
                    }
                } else if layout.solidFraction > 0 {
                    Capsule()
                        .fill(fillColor.gradient)
                        .frame(width: width * layout.solidFraction)
                }
            }
        }
        .frame(height: height)
    }
}

#Preview("Macro: Under Goal") {
    GoalProgressBar(amount: 40, goal: 100, dashedThreshold: 100, fillColor: .green, exceededFillColor: .green.opacity(0.25), exceededOutlineColor: .green)
        .frame(width: 160)
        .padding()
}

#Preview("Macro: Over Goal") {
    GoalProgressBar(amount: 140, goal: 100, dashedThreshold: 100, fillColor: .green, exceededFillColor: .green.opacity(0.25), exceededOutlineColor: .green)
        .frame(width: 160)
        .padding()
}

#Preview("Vitamin: Over Goal, Under Upper Limit") {
    GoalProgressBar(amount: 150, goal: 100, dashedThreshold: 400, fillColor: .green, exceededFillColor: .red.opacity(0.25), exceededOutlineColor: .red)
        .frame(width: 160)
        .padding()
}

#Preview("Vitamin: Over Upper Limit") {
    GoalProgressBar(amount: 500, goal: 100, dashedThreshold: 400, fillColor: .green, exceededFillColor: .red.opacity(0.25), exceededOutlineColor: .red)
        .frame(width: 160)
        .padding()
}
