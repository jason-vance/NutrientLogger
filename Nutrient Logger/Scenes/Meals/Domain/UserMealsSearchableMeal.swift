//
//  UserMealsSearchableMeal.swift
//  NutrientLogger
//
//  Created by Jason Vance on 9/24/21.
//

import Foundation

public struct UserMealsSearchableMeal: Equatable {
    public var mealId: Int
    public var foodId: Int
    public var mealName: String
    public var foodName: String
    public var rank: Double
}

