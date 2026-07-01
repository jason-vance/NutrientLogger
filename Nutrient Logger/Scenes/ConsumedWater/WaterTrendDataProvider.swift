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
        startDate: SimpleDate,
        endDate: SimpleDate,
        unit: WaterUnit
    ) -> [DailyNutrientTotal] {
        let directByDate = Dictionary(grouping: directWaterData) { $0.date }

        var results: [DailyNutrientTotal] = []
        var current = startDate
        while current <= endDate {
            let grams = (directByDate[current] ?? []).reduce(0) { $0 + $1.amountGrams }
            results.append(DailyNutrientTotal(date: current, amount: unit.fromGrams(grams)))
            current = current.adding(days: 1)
        }
        return results
    }
}
