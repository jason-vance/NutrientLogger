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
    
    var order: Int {
        switch self {
        case .breakfast:
            return 1
        case .morningSnack:
            return 2
        case .lunch:
            return 3
        case .afternoonSnack:
            return 4
        case .dinner:
            return 5
        case .eveningSnack:
            return 6
        case .none:
            return 7
        }
    }
    
    static let validFields: [MealTime] = [
        .breakfast, .morningSnack, .lunch, .afternoonSnack, .dinner, .eveningSnack
    ]
}

extension MealTime: Codable {}

extension MealTime: Comparable {
    
    static func < (lhs: MealTime, rhs: MealTime) -> Bool {
        lhs.order < rhs.order
    }
}
