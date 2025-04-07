//
//  RemoteDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public protocol RemoteDatabase {
    func search(_ query: String) throws -> SearchResult
    func getFood(_ foodId: String) throws -> FoodItem?
    func getPortions(_ food: FoodItem) throws -> [Portion]
    func getAllNutrients() throws -> [Nutrient]
    func getAllNutrientsLinkedToFoods() throws -> [Nutrient]
    func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair]
}
