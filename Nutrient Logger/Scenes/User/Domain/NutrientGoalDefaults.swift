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
        if let macroRdi = macroGoalRdi(for: nutrientId, user: user) {
            return macroRdi
        }

        let baseRdi = rdiLibrary.getRdis(nutrientId)?.getRdi(user)

        let customGoal = user.micronutrientGoals[nutrientId]
        let customUpperLimit = user.micronutrientUpperLimits[nutrientId]

        guard customGoal != nil || customUpperLimit != nil else {
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
            recommendedAmount: customGoal ?? baseRdi?.recommendedAmount ?? 0,
            upperLimit: customUpperLimit ?? baseRdi?.upperLimit ?? .greatestFiniteMagnitude,
            unit: unit
        )
    }

    /// The upper limit the RDI library would use for this nutrient, ignoring any custom
    /// limit the user has set. Drives the placeholder in the limit editor.
    static func defaultUpperLimit(
        for nutrientId: String,
        user: User,
        rdiLibrary: NutrientRdiLibrary
    ) -> Double? {
        guard let upperLimit = rdiLibrary.getRdis(nutrientId)?.getRdi(user)?.upperLimit else { return nil }
        guard upperLimit > 0, upperLimit < .greatestFiniteMagnitude else { return nil }
        return upperLimit
    }

    private static func macroGoalRdi(for nutrientId: String, user: User) -> LifeStageNutrientRdi? {
        let (recommendedAmount, unit): (Double, WeightUnit)
        switch nutrientId {
        case FdcNutrientGroupMapper.NutrientNumber_Energy_KCal:
            (recommendedAmount, unit) = (user.calorieGoal ?? defaultCalorieGoal(for: user), .calories)
        case FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference:
            (recommendedAmount, unit) = (user.carbsGoalGrams ?? defaultCarbsGoal(for: user), .gram)
        case FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat:
            (recommendedAmount, unit) = (user.fatGoalGrams ?? defaultFatGoal(for: user), .gram)
        case FdcNutrientGroupMapper.NutrientNumber_Protein:
            (recommendedAmount, unit) = (user.proteinGoalGrams ?? defaultProteinGoal(for: user), .gram)
        default:
            return nil
        }

        return LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientId,
            gender: .unknown,
            minAgeYears: 0,
            maxAgeYears: .greatestFiniteMagnitude,
            recommendedAmount: recommendedAmount,
            upperLimit: .greatestFiniteMagnitude,
            unit: unit
        )
    }
}
