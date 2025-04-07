//
//  MockUserMealAnalytics.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class MockUserMealAnalytics: UserMealAnalytics {
    
    public var loadMealFailures = [Error]()
    public var foodsAdded = [FoodItem]()
    public var foodFailedToAdd = [FoodItem]()
    public var foodsDeleted = 0
    public var foodDeletionFailures = [Error]()
    
    public func loadMealFailed(_ error: Error) {
        loadMealFailures.append(error)
    }
    
    public func foodAddedToMeal(_ food: FoodItem) {
        foodsAdded.append(food)
    }
    
    public func addFoodToMealFailed(_ food: FoodItem) {
        foodFailedToAdd.append(food)
    }
    
    public func foodDeletedFromMeal() {
        foodsDeleted = foodsDeleted + 1
    }
    
    public func deletingFoodFromMealFailed(_ error: Error) {
        foodDeletionFailures.append(error)
    }
}
