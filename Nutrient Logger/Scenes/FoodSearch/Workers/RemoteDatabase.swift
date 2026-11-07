//
//  RemoteDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

protocol RemoteDatabase {
    func search(_ query: String) throws -> [FdcSearchableFood]
    func searchSimilar(productName: String, brand: String?, limit: Int) throws -> [FdcSearchableFood]
    func correctedQuery(for query: String) -> String?
    func searchParts(for query: String) -> [SearchQueryPart]
    func getFood(_ foodId: String) throws -> FoodItem?
    func getPortions(_ food: FoodItem) throws -> [Portion]
    func getNutrient(withId: String) -> Nutrient?
    func getAllNutrients() throws -> [Nutrient]
    func getAllNutrientsLinkedToFoods() throws -> [Nutrient]
    func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair]
}

extension RemoteDatabase {
    func correctedQuery(for query: String) -> String? { nil }

    func searchParts(for query: String) -> [SearchQueryPart] { [] }

    func searchSimilar(productName: String, brand: String?, limit: Int) throws -> [FdcSearchableFood] {
        []
    }
}

/// One food named inside a search that found nothing as a whole.
struct SearchQueryPart: Equatable {
    /// What to show as the section title, from the user's own words: "Cream cheese".
    let name: String
    /// What to search for. Can differ from `name` when a typo or synonym was fixed.
    let query: String
}
