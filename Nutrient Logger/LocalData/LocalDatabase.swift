//
//  LocalDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public protocol LocalDatabase {
    var hasDataChanged: Bool { get }
    func resetHasDataChanged()
    func saveFoodItem(_ food: FoodItem) throws
    func getFoodsOrderedByDateLogged(_ date: Date) throws -> [FoodItem]
    func deleteFood(_ food: FoodItem) throws
    func getFood(_ id: Int) throws -> FoodItem?
    func getEarliestFood() throws -> FoodItem?
    func getMostRecentFood() throws -> FoodItem?
    func getRecentlyLoggedFoods(_ limit: Int) throws -> [FoodItem]
}
