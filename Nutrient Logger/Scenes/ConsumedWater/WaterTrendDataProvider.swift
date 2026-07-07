//
//  WaterTrendDataProvider.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import Foundation

class WaterTrendDataProvider {

    func dailyTotals(
        directWaterData: [(date: SimpleDate, amountGrams: Double)],
        foodWaterGramsByDate: [SimpleDate: Double] = [:],
        startDate: SimpleDate,
        endDate: SimpleDate,
        unit: WaterUnit
    ) -> [DailyNutrientTotal] {
        let directByDate = Dictionary(grouping: directWaterData) { $0.date }

        var results: [DailyNutrientTotal] = []
        var current = startDate
        while current <= endDate {
            let directGrams = (directByDate[current] ?? []).reduce(0) { $0 + $1.amountGrams }
            let foodGrams = foodWaterGramsByDate[current] ?? 0
            results.append(DailyNutrientTotal(date: current, amount: unit.fromGrams(directGrams + foodGrams)))
            current = current.adding(days: 1)
        }
        return results
    }
}
