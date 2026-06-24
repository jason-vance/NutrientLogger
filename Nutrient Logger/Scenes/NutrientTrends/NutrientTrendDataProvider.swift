//
//  NutrientTrendDataProvider.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import Foundation
import SwiftData

struct DailyNutrientTotal: Identifiable {
    var id: SimpleDate { date }
    let date: SimpleDate
    let amount: Double
}

class NutrientTrendDataProvider {

    private let remoteDatabase: RemoteDatabase

    init(remoteDatabase: RemoteDatabase) {
        self.remoteDatabase = remoteDatabase
    }

    func dailyTotals(
        for nutrientNumber: String,
        consumedFoods: [ConsumedFood],
        startDate: SimpleDate,
        endDate: SimpleDate
    ) -> [DailyNutrientTotal] {
        let foodsByDate = Dictionary(grouping: consumedFoods) { $0.dateLogged }

        var results: [DailyNutrientTotal] = []
        var current = startDate
        while current <= endDate {
            let foods = foodsByDate[current] ?? []
            let amount = totalForNutrient(nutrientNumber, from: foods)
            results.append(DailyNutrientTotal(date: current, amount: amount))
            current = current.adding(days: 1)
        }
        return results
    }

    private func totalForNutrient(_ nutrientNumber: String, from consumedFoods: [ConsumedFood]) -> Double {
        let foodItems: [FoodItem] = consumedFoods.compactMap { consumed in
            do {
                var food = try remoteDatabase.getFood(String(consumed.fdcId))
                food = try food?.applyingPortion(consumed.portion)
                return food
            } catch {
                return nil
            }
        }

        let aggregator = NutrientDataAggregator(foodItems)
        guard let pairs = aggregator.nutrientsByNutrientNumber[nutrientNumber] else {
            return 0
        }
        return pairs.reduce(0) { $0 + $1.nutrient.amount }
    }

    static func dateRange(days: Int, endingOn endDate: SimpleDate) -> (start: SimpleDate, end: SimpleDate) {
        let start = endDate.adding(days: -(days - 1))
        return (start, endDate)
    }
}
