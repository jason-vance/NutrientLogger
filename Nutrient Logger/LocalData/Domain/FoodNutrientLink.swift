//
//  FoodNutrientLink.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public struct FoodNutrientLink: DatabaseEntity {
    public var id: Int = -1
    public var created: Date = Date.now
    public var foodId: Int
    public var nutrientId: Int
}
