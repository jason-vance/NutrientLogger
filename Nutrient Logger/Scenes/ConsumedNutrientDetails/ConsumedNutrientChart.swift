//
//  ConsumedNutrientChart.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/11/25.
//

import SwiftUI

struct ConsumedNutrientChart: View {
    
    let capsuleSpacing: CGFloat = 4
    
    enum Style {
        case cumulative
        case individual
    }
    
    struct ChartValue: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let value: Double
    }
    
    private let mealTimeValueMap: [MealTime:Double]
    private let rdi: LifeStageNutrientRdi?
    private let style: Style
    
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
    
    private var recommendedString: String? {
        guard let recommendedValue else { return nil }
        return "Recommended Amount: \(recommendedValue.formatted(maxDigits: 2))\(weightUnit)"
    }
    
    private var upperLimit: Double? {
        guard let rdi else { return nil }
        guard rdi.upperLimit > 0, rdi.upperLimit < .greatestFiniteMagnitude else { return nil }
        return rdi.upperLimit
    }
    
    private var upperLimitString: String? {
        guard let upperLimit else { return nil }
        return "Upper Limit: \(upperLimit.formatted(maxDigits: 2))\(weightUnit)"
    }
    
    private var chartMaxValue: Double {
        let maxNutrientValue = {
            switch style {
            case .cumulative:
                chartValues.reduce(into: 0) { $0 += $1.value }
            case .individual:
                chartValues.map { $0.value }.max() ?? 0
            }
        }()
        let max = max(maxNutrientValue, recommendedValue ?? 0)
        return max
    }
    
    private func capsuleSize(
        width: CGFloat
    ) -> CGFloat {
        var multiplier: CGFloat = 1
        switch style {
        case .cumulative: multiplier = 2; break;
        default: multiplier = 1; break;
        }
        
        return (width / (multiplier * CGFloat(MealTime.validFields.count))) - capsuleSpacing
    }
    
    private func capsuleOffset(
        _ chartValue: ChartValue,
        unitsPerHeight: CGFloat
    ) -> CGFloat {
        switch style {
        case .individual:
            return 0
        case .cumulative:
            let indexOfMealTime = chartValues.firstIndex { $0.mealTime == chartValue.mealTime }
            let cumulation = chartValues[0..<indexOfMealTime!].reduce(into: 0) { $0 += $1.value }
            return -(cumulation * unitsPerHeight)
        }
    }
    
    init(
        nutrientFoodPairs: [NutrientFoodPair],
        rdi: LifeStageNutrientRdi?,
        style: Style
    ) {
        self.mealTimeValueMap = nutrientFoodPairs
            .reduce(into: [:]) { result, pair in
                if let mealTime = pair.nutrient.mealTime {
                    result[mealTime, default: 0] += pair.nutrient.amount
                }
            }
        
        self.rdi = rdi
        self.style = style
    }
    
    var body: some View {
        GeometryReader { geometry in
            let capsuleSize = capsuleSize(width: geometry.size.width)
            let chartHeight = geometry.size.height - capsuleSize
            let unitsPerHeight = chartHeight / chartMaxValue
            
            ZStack {
                Capsules(unitsPerHeight: unitsPerHeight, capsuleSize: capsuleSize)
                if style == .cumulative {
                    RecommendedAmount(unitsPerHeight: unitsPerHeight, capsuleSize: capsuleSize)
                    UpperLimit(unitsPerHeight: unitsPerHeight, capsuleSize: capsuleSize, chartHeight: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private func Capsules(
        unitsPerHeight: CGFloat,
        capsuleSize: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(chartValues) { chartValue in
                let offset = capsuleOffset(chartValue, unitsPerHeight: unitsPerHeight)
                let height = (chartValue.value * unitsPerHeight) + capsuleSize
                let showDoubleCapsule = style == .cumulative
                
                if showDoubleCapsule {
                    if chartValue.mealTime != .breakfast {
                        Spacer(minLength: 0)
                    }
                    VStack {
                        Spacer(minLength: 0)
                        Capsule(style: .continuous)
                            .frame(width: capsuleSize, height: capsuleSize)
                            .offset(y: offset)
                    }
                }
                if showDoubleCapsule || chartValue.mealTime != .breakfast {
                    Spacer(minLength: 0)
                }
                VStack {
                    Spacer(minLength: 0)
                    Capsule(style: .continuous)
                        .frame(width: capsuleSize, height: height)
                        .offset(y: offset)
                }
            }
        }
    }
    
    @ViewBuilder private func RecommendedAmount(
        unitsPerHeight: CGFloat,
        capsuleSize: CGFloat
    ) -> some View {
        if let recommendedValue = recommendedValue, let recommendedString = recommendedString {
            let offset = -(recommendedValue * unitsPerHeight)
            
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .offset(y: offset)
                    .overlay(alignment: .bottom) {
                        HStack {
                            Text(recommendedString)
                                .font(.caption)
                            Spacer()
                        }
                        .offset(y: offset)
                    }
            }
            .foregroundStyle(Color.black.opacity(0.5))
        }
    }
    
    @ViewBuilder private func UpperLimit(
        unitsPerHeight: CGFloat,
        capsuleSize: CGFloat,
        chartHeight: CGFloat
    ) -> some View {
        if let upperLimit = upperLimit, let upperLimitString = upperLimitString {
            let offset = -(upperLimit * unitsPerHeight)

            if -offset < chartHeight {
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .offset(y: offset)
                        .overlay(alignment: .bottom) {
                            HStack {
                                Text(upperLimitString)
                                    .font(.caption)
                                Spacer()
                            }
                            .offset(y: offset)
                        }
                }
                .foregroundStyle(Color.black.opacity(0.5))
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
            style: .individual
        )
        .frame(height: 250)
        ConsumedNutrientChart(
            nutrientFoodPairs: pairs!,
            rdi: rdi,
            style: .cumulative
        )
        .frame(height: 250)
    }
    .listDefaultModifiers()
}
