//
//  MockLocalDatabase.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class MockLocalDatabase: LocalDatabase {
    public var hasDataChanged: Bool = false
    
    public var errorToThrow: Error?
    
    public var foodsFor_getFoodsOrderedByDateLogged: [FoodItem] = []
    public var foodsFor_getRecentlyLoggedFoods: [FoodItem] = []
    public var foodFor_getFood: FoodItem?
    public var earliestFood: FoodItem?
    public var mostRecentFood: FoodItem?

    public var savedFoods: [FoodItem] = []
    public var deletedFoods: [FoodItem] = []

    public func resetHasDataChanged() {
        hasDataChanged = false
    }
    
    public func saveFoodItem(_ food: FoodItem) throws {
        if let error = errorToThrow {
            throw error
        }
        savedFoods.append(food)
    }
    
    public func getFoodsOrderedByDateLogged(_ date: Date) throws -> [FoodItem] {
        if let error = errorToThrow {
            throw error
        }
        return foodsFor_getFoodsOrderedByDateLogged
    }
    
    public func deleteFood(_ food: FoodItem) throws {
        if let error = errorToThrow {
            throw error
        }
        deletedFoods.append(food)
    }
    
    public func getFood(_ id: Int) throws -> FoodItem? {
        if let error = errorToThrow {
            throw error
        }
        return foodFor_getFood
    }
    
    public func getEarliestFood() throws -> FoodItem? {
        if let error = errorToThrow {
            throw error
        }
        return earliestFood
    }
    
    public func getMostRecentFood() throws -> FoodItem? {
        if let error = errorToThrow {
            throw error
        }
        return mostRecentFood
    }
    
    public func getRecentlyLoggedFoods(_ limit: Int) throws -> [FoodItem] {
        if let error = errorToThrow {
            throw error
        }
        return foodsFor_getRecentlyLoggedFoods
    }
}
