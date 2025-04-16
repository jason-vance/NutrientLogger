//
//  UserMealsSearchableMeal.swift
//  NutrientLogger
//
//  Created by Jason Vance on 9/24/21.
//

import Foundation

struct UserMealsSearchableMeal: Equatable {
    public var meal: Meal
    public var foodId: Int
    public var foodName: String
    public var rank: Double
    
    var mealName: String { meal.name }
    
    init(meal: Meal) {
        self.meal = meal
        self.foodId = -1
        self.foodName = ""
        self.rank = 0
    }
}

