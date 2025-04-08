//
//  MockConsumedFoodSaverAnalytics.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

class MockConsumedFoodSaverAnalytics: ConsumedFoodSaverAnalytics {
    public var foodsLogged = [FoodItem]()
    public var foodLoggedFailures = [FoodItem]()
    
    public func foodLogged(_ food: FoodItem) {
        foodsLogged.append(food)
    }
    
    public func foodLogFailed(_ food: FoodItem) {
        foodLoggedFailures.append(food)
    }
}
