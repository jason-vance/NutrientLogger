//
//  MockRemoteDatabase.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

class MockRemoteDatabase: RemoteDatabase {
    public var errorToThrow: Error?
    
    public var result_for_search = SearchResult([])
    public var foods_for_getFood: [String:FoodItem] = [:]
    public var portions_for_getPortions = [Portion]()
    public var nutrients_for_getAllNutrients = [Nutrient]()
    public var nutrients_for_getAllNutrientsLinkedToFoods = [Nutrient]()
    public var foods_for_getFoodsContainingNutrient = [NutrientFoodPair]()

    public func search(_ query: String) throws -> SearchResult {
        if let error = errorToThrow {
            throw error
        }
        return result_for_search
    }
    
    public func getFood(_ foodId: String) throws -> FoodItem? {
        if let error = errorToThrow {
            throw error
        }
        return foods_for_getFood[foodId]
    }
    
    public func getPortions(_ food: FoodItem) throws -> [Portion] {
        if let error = errorToThrow {
            throw error
        }
        return portions_for_getPortions
    }
    
    public func getAllNutrients() throws -> [Nutrient] {
        if let error = errorToThrow {
            throw error
        }
        return nutrients_for_getAllNutrients
    }
    
    public func getAllNutrientsLinkedToFoods() throws -> [Nutrient] {
        if let error = errorToThrow {
            throw error
        }
        return nutrients_for_getAllNutrientsLinkedToFoods
    }
    
    public func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair] {
        if let error = errorToThrow {
            throw error
        }
        return foods_for_getFoodsContainingNutrient
    }
    
    
}
