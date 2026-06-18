//
//  NutrientGoalDefaults.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/17/26.
//

import Foundation

struct NutrientGoalDefaults {

    static func defaultCalorieGoal(for user: User) -> Double {
        switch user.gender {
        case .male: return 2500
        case .female, .unknown: return 2000
        }
    }

    static func defaultCarbsGoal(for user: User) -> Double {
        let calories = user.calorieGoal ?? defaultCalorieGoal(for: user)
        return (calories * 0.50 / 4).rounded()
    }

    static func defaultFatGoal(for user: User) -> Double {
        let calories = user.calorieGoal ?? defaultCalorieGoal(for: user)
        return (calories * 0.30 / 9).rounded()
    }

    static func defaultProteinGoal(for user: User) -> Double {
        let calories = user.calorieGoal ?? defaultCalorieGoal(for: user)
        return (calories * 0.20 / 4).rounded()
    }
}
