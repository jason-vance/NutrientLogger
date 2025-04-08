//
//  MealTime.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum MealTime: String {
    case none = "No Meal Time"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case morningSnack = "Morning Snack"
    case afternoonSnack = "Afternoon Snack"
    case eveningSnack = "Evening Snack"
}

extension MealTime: Codable {}
