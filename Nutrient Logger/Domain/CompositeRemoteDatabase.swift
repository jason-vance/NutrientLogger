//
//  CompositeRemoteDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/16/26.
//

import Foundation

// Routes getFood / getPortions calls to CustomFoodDatabase for negative fdcIds
// and to BundledFdcDatabase for all others.
class CompositeRemoteDatabase: RemoteDatabase {

    private let fdc: BundledFdcDatabase
    private let custom: CustomFoodDatabase

    init(fdc: BundledFdcDatabase, custom: CustomFoodDatabase) {
        self.fdc = fdc
        self.custom = custom
    }

    func getFood(_ foodId: String) throws -> FoodItem? {
        guard let id = Int(foodId) else { return nil }
        if id < 0 {
            return custom.getFoodItem(withId: id)
        }
        return try fdc.getFood(foodId)
    }

    func getPortions(_ food: FoodItem) throws -> [Portion] {
        if food.fdcId < 0 {
            return custom.getPortions(forId: food.fdcId)
        }
        return try fdc.getPortions(food)
    }

    func search(_ query: String) throws -> [FdcSearchableFood] {
        try fdc.search(query)
    }

    func searchSimilar(productName: String, brand: String?, limit: Int) throws -> [FdcSearchableFood] {
        try fdc.searchSimilar(productName: productName, brand: brand, limit: limit)
    }

    func getNutrient(withId id: String) -> Nutrient? {
        fdc.getNutrient(withId: id)
    }

    func getAllNutrients() throws -> [Nutrient] {
        try fdc.getAllNutrients()
    }

    func getAllNutrientsLinkedToFoods() throws -> [Nutrient] {
        try fdc.getAllNutrientsLinkedToFoods()
    }

    func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair] {
        try fdc.getFoodsContainingNutrient(nutrient)
    }
}
