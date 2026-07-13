//
//  NutrientFoodPair.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

struct NutrientFoodPair: Equatable, Identifiable {

    // Includes date/meal/portion, not just nutrient+fdcId, so two separate log entries of the
    // same food (e.g. eggs logged for both breakfast and dinner) don't collide on identity.
    var id: String {
        "\(nutrient.fdcNumber)-\(food.fdcId)-\(food.dateLogged ?? 0)-\(food.mealTime?.rawValue ?? "")-\(food.portionName)-\(food.amount)"
    }

    public let nutrient: Nutrient
    public let food: FoodItem
}
