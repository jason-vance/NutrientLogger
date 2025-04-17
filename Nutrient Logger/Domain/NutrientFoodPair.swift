//
//  NutrientFoodPair.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

struct NutrientFoodPair: Equatable, Identifiable {
    
    var id: String { "\(nutrient.fdcNumber)-\(food.fdcId)" }
    
    public let nutrient: Nutrient
    public let food: FoodItem
}
