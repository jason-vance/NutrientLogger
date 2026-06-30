//
//  CalorieGoalRing.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/29/26.
//

import SwiftUI

struct CalorieGoalRing: View {

    struct Config {
        let lineWidth: CGFloat
        let margin: CGFloat
        let trackColor: Color
        let fillColor: Color
        let excessColor: Color
        let excessOutlineColor: Color
        let excessOutlineWidth: CGFloat
        let excessOutlineDashLength: CGFloat
        let excessOutlineDashGap: CGFloat

        init(
            lineWidth: CGFloat = 8,
            margin: CGFloat = 6,
            trackColor: Color = Color.gray.opacity(0.2),
            fillColor: Color = Color.gray.opacity(0.6),
            excessColor: Color = Color.orange.opacity(0.25),
            excessOutlineColor: Color = Color.orange,
            excessOutlineWidth: CGFloat = 1,
            excessOutlineDashLength: CGFloat = 1.5,
            excessOutlineDashGap: CGFloat = 1.5
        ) {
            self.lineWidth = lineWidth
            self.margin = margin
            self.trackColor = trackColor
            self.fillColor = fillColor
            self.excessColor = excessColor
            self.excessOutlineColor = excessOutlineColor
            self.excessOutlineWidth = excessOutlineWidth
            self.excessOutlineDashLength = excessOutlineDashLength
            self.excessOutlineDashGap = excessOutlineDashGap
        }
    }

    let calories: Double
    let calorieGoal: Double?
    let config: Config

    init(
        calories: Double,
        calorieGoal: Double?,
        config: Config = Config()
    ) {
        self.calories = calories
        self.calorieGoal = calorieGoal
        self.config = config
    }

    var body: some View {
        GeometryReader { geometry in
            if let calorieGoal, calorieGoal > 0 {
                let circumference: CGFloat = geometry.size.width * .pi
                let lineWidth: CGFloat = config.lineWidth / circumference
                let margin: CGFloat = config.margin / circumference

                ZStack {
                    if calories <= calorieGoal {
                        Circle()
                            .stroke(style: .init(lineWidth: config.lineWidth))
                            .foregroundStyle(config.trackColor)

                        let progress = CGFloat(calories / calorieGoal)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(style: .init(lineWidth: config.lineWidth, lineCap: .round))
                            .foregroundStyle(config.fillColor)
                            .rotationEffect(.degrees(-90))
                    } else {
                        let excess = calories - calorieGoal
                        let total = calories
                        let goalFraction = CGFloat(calorieGoal / total)
                        let excessFraction = CGFloat(excess / total)

                        let sectors: CGFloat = 2
                        let emptyCircumference = (sectors * lineWidth) + (sectors * margin)
                        let circumRatio = 1 - emptyCircumference

                        let goalStart = (lineWidth / 2) + (margin / 2)
                        let goalEnd = goalStart + goalFraction * circumRatio
                        let goalEndWithSpace = goalEnd + (lineWidth / 2) + (margin / 2)

                        let excessStart = goalEndWithSpace + (lineWidth / 2) + (margin / 2)
                        let excessEnd = excessStart + excessFraction * circumRatio

                        Circle()
                            .trim(from: goalStart, to: goalEnd)
                            .stroke(style: .init(lineWidth: config.lineWidth, lineCap: .round))
                            .foregroundStyle(config.fillColor)
                            .rotationEffect(.degrees(-90))

                        let excessShape = Circle()
                            .trim(from: excessStart, to: excessEnd)
                            .stroke(style: StrokeStyle(lineWidth: config.lineWidth, lineCap: .round))
                            .rotation(.degrees(-90))

                        excessShape
                            .fill(config.excessColor)

                        excessShape
                            .stroke(
                                config.excessOutlineColor,
                                style: StrokeStyle(
                                    lineWidth: config.excessOutlineWidth,
                                    dash: [config.excessOutlineDashLength, config.excessOutlineDashGap]
                                )
                            )
                    }
                }
            }
        }
        .padding(config.lineWidth / 2)
    }
}

#Preview("Under Goal") {
    CalorieGoalRing(calories: 1250, calorieGoal: 2000)
        .frame(width: 200, height: 200)
}

#Preview("Over Goal") {
    CalorieGoalRing(calories: 2600, calorieGoal: 2000)
        .frame(width: 200, height: 200)
}

#Preview("Way Over Goal") {
    CalorieGoalRing(calories: 4000, calorieGoal: 2000)
        .frame(width: 200, height: 200)
}

#Preview("No Goal") {
    CalorieGoalRing(calories: 1250, calorieGoal: nil)
        .frame(width: 200, height: 200)
}
