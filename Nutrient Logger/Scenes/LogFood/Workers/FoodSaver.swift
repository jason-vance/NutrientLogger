//
//  FoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public enum FoodSaverType {
    case consumedFoodSaver
    case mealFoodSaver
}

public enum FoodSaverErrors: Error {
    case mealIdNotSet
}

public protocol FoodSaver {
    var foodSaverType: FoodSaverType { get }
    var needsPortion: Bool { get }
    var needsDateTime: Bool { get }
    
    func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws
}
