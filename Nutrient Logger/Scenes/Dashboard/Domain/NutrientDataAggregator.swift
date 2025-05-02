//
//  NutrientDataAggregator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

class NutrientDataAggregator {
    public var nutrientGroups = [NutrientGroup]()
    public var nutrientsByNutrientNumber = [String:[NutrientFoodPair]]()

    let foods: [FoodItem]

    public init(_ foods: [FoodItem]) {
        self.foods = foods
        aggregate()
    }

    private func aggregate() {
        organizeNutrientsAndFoods()

        var aggregates = [Nutrient]()
        for key in nutrientsByNutrientNumber.keys {
            let nutrients = nutrientsByNutrientNumber[key]!.map { $0.nutrient }

            if let nutrient = NutrientDataAggregator.combineNutrients(nutrients) {
                if (nutrient.amount > 0) {
                    aggregates.append(nutrient)
                }
            }
        }

        nutrientGroups = FdcNutrientGrouper.group(aggregates)
            .sorted { $0.rank < $1.rank }
    }

    private func organizeNutrientsAndFoods() {
        nutrientsByNutrientNumber = [:]

        for food in foods {
            for group in food.nutrientGroups {
                for nutrient in group.nutrients {
                    if (!nutrientsByNutrientNumber.keys.contains(nutrient.fdcNumber)) {
                        nutrientsByNutrientNumber[nutrient.fdcNumber] = []
                    }
                    let pair = NutrientFoodPair(nutrient: nutrient, food: food)
                    nutrientsByNutrientNumber[nutrient.fdcNumber]!.append(pair)
                }
            }
        }
    }

    public static func combineNutrients(_ nutrients: [Nutrient]) -> Nutrient? {
        if (nutrients.isEmpty) {
            return nil
        }

        let toUnit = getFirstWeightUnit(nutrients)

        var total = 0.0
        for nutrient in nutrients {
            let fromUnit = WeightUnit.unitFrom(nutrient)
            total += fromUnit.convertTo(toUnit, nutrient.amount)
        }

        return Nutrient(
            fdcId: nutrients[0].fdcId,
            fdcNumber: nutrients[0].fdcNumber,
            name: nutrients[0].name,
            unitName: toUnit.name,
            amount: total
        )
    }

    private static func getFirstWeightUnit(_ nutrients: [Nutrient]) -> WeightUnit {
        var toUnit = WeightUnit.unknown
        for nutrient in nutrients {
            if (toUnit != WeightUnit.unknown) {
                break
            }
            toUnit = WeightUnit.unitFrom(nutrient)
        }
        return toUnit
    }
    
    var waterCups: Double {
        if let waters = nutrientsByNutrientNumber[FdcNutrientGroupMapper.NutrientNumber_Water] {
            let waterGrams = waters.reduce(0.0) { $0 + $1.nutrient.amount }
            let gramsPerCup: Double = 237
            return waterGrams / gramsPerCup
        }
        return 0
    }
}
