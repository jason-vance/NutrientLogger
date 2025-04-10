//
//  FoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum FoodSaverType {
    case consumedFoodSaver
    case mealFoodSaver
}

enum FoodSaverErrors: Error {
    case mealIdNotSet
}

protocol FoodSaver {
    var foodSaverType: FoodSaverType { get }
    var needsPortion: Bool { get }
    var needsDateTime: Bool { get }
    
    func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws
}
