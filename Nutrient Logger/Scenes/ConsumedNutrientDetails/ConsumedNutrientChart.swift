//
//  ConsumedNutrientChart.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/11/25.
//

import SwiftUI
import Charts

struct ConsumedNutrientChart: View {

    enum Style {
        case cumulative
        case individual
    }

    struct ChartValue: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let value: Double
    }

    private let mealTimeValueMap: [MealTime: Double]
    private let rdi: LifeStageNutrientRdi?
    private let style: Style
    let accentColor: Color

    private var chartValues: [ChartValue] {
        MealTime.validFields
            .map { mealTime in
                ChartValue(mealTime: mealTime, value: mealTimeValueMap[mealTime, default: 0])
            }
    }

    private var weightUnit: String {
        rdi?.unit.name ?? ""
    }

    private var recommendedValue: Double? {
        guard let rdi else { return nil }
        guard rdi.recommendedAmount > 0, rdi.recommendedAmount < .greatestFiniteMagnitude else { return nil }
        return rdi.recommendedAmount
    }

    private static let upperLimitProximityThreshold: Double = 0.8

    private var totalConsumed: Double {
        mealTimeValueMap.values.reduce(0, +)
    }

    private var upperLimit: Double? {
        guard let rdi else { return nil }
        guard rdi.upperLimit > 0, rdi.upperLimit < .greatestFiniteMagnitude else { return nil }
        guard totalConsumed >= rdi.upperLimit * Self.upperLimitProximityThreshold else { return nil }
        return rdi.upperLimit
    }

    init(
        nutrientFoodPairs: [NutrientFoodPair],
        rdi: LifeStageNutrientRdi?,
        style: Style,
        accentColor: Color = .blue
    ) {
        self.mealTimeValueMap = nutrientFoodPairs
            .reduce(into: [:]) { result, pair in
                if let mealTime = pair.nutrient.mealTime {
                    result[mealTime, default: 0] += pair.nutrient.amount
                }
            }

        self.rdi = {
            guard let first = nutrientFoodPairs.first else { return rdi }
            let foodsUnit: WeightUnit = .unitFrom(first.nutrient)
            if foodsUnit == rdi?.unit { return rdi }
            guard let rdi else { return nil }
            return rdi.convertedTo(foodsUnit)
        }()
        self.style = style
        self.accentColor = accentColor
    }

    var body: some View {
        switch style {
        case .individual: IndividualChart()
        case .cumulative: CumulativeChart()
        }
    }

    @ViewBuilder private func IndividualChart() -> some View {
        Chart {
            ForEach(chartValues) { cv in
                BarMark(
                    x: .value("Meal", cv.mealTime.rawValue),
                    y: .value("Amount", cv.value)
                )
                .foregroundStyle(accentColor.gradient)
                .cornerRadius(4)
            }
            RefLines()
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
    }

    @ViewBuilder private func CumulativeChart() -> some View {
        Chart {
            ForEach(chartValues) { cv in
                BarMark(
                    x: .value("", "Total"),
                    y: .value("Amount", cv.value)
                )
                .foregroundStyle(by: .value("Meal", cv.mealTime.rawValue))
                .cornerRadius(2)
            }
            RefLines()
        }
        .chartForegroundStyleScale(
            domain: MealTime.validFields.map(\.rawValue),
            range: mealColorRange
        )
        .chartXAxis(.hidden)
        .chartLegend(position: .bottom, alignment: .center)
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
    }

    private var mealColorRange: [Color] {
        let opacities: [Double] = [1.0, 0.85, 0.70, 0.55, 0.40, 0.25]
        return opacities.map { accentColor.opacity($0) }
    }

    @ChartContentBuilder private func RefLines() -> some ChartContent {
        if let rec = recommendedValue {
            RuleMark(y: .value("Recommended", rec))
                .foregroundStyle(Color.text.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Recommended: \(rec.formatted(maxDigits: 2))\(weightUnit)")
                        .font(.caption)
                        .foregroundStyle(Color.text.opacity(0.5))
                }
        }
        if let ul = upperLimit {
            RuleMark(y: .value("Upper Limit", ul))
                .foregroundStyle(Color.orange.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Upper Limit: \(ul.formatted(maxDigits: 2))\(weightUnit)")
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.7))
                }
        }
    }
}

#Preview {
    let pairs = NutrientDataAggregator(FoodItem.sampleFoods)
        .nutrientsByNutrientNumber[FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca]

    let rdi = UsdaNutrientRdiLibrary
        .create()
        .getRdis(FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca)?
        .getRdi(.sample)

    List {
        ConsumedNutrientChart(
            nutrientFoodPairs: pairs!,
            rdi: rdi,
            style: .individual,
            accentColor: .red
        )
        .frame(height: 250)
        ConsumedNutrientChart(
            nutrientFoodPairs: pairs!,
            rdi: rdi,
            style: .cumulative,
            accentColor: .blue
        )
        .frame(height: 250)
    }
    .listDefaultModifiers()
}
