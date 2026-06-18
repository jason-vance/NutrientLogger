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

    static func effectiveRdi(
        for nutrientId: String,
        user: User,
        rdiLibrary: NutrientRdiLibrary
    ) -> LifeStageNutrientRdi? {
        let baseRdi = rdiLibrary.getRdis(nutrientId)?.getRdi(user)

        guard let customGoal = user.micronutrientGoals[nutrientId] else {
            return baseRdi
        }

        let unit: WeightUnit = baseRdi?.unit
            ?? rdiLibrary.getRdis(nutrientId)?.getRdi(.unknown, 30 * 365 * 86400)?.unit
            ?? .unknown

        return LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientId,
            gender: .unknown,
            minAgeYears: 0,
            maxAgeYears: .greatestFiniteMagnitude,
            recommendedAmount: customGoal,
            upperLimit: baseRdi?.upperLimit ?? .greatestFiniteMagnitude,
            unit: unit
        )
    }
}
