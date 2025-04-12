//
//  DatabaseMealTime.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import Foundation

typealias DatabaseMealTime = String

extension DatabaseMealTime {
    static func from(_ mealTime: MealTime) -> DatabaseMealTime {
        return mealTime.rawValue
    }
    
    func toMealTime() -> MealTime? {
        return MealTime(rawValue: self)
    }
}
