//
//  BmrCalculator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import Foundation

struct BmrCalculator {

    /// Mifflin-St Jeor equation. Returns kcal/day at rest.
    static func bmr(weightKg: Double, heightCm: Double, ageYears: Int, gender: Gender) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears))
        switch gender {
        case .male:    return base + 5
        case .female:  return base - 161
        case .unknown: return base - 78  // midpoint of male/female constants
        }
    }

    static func tdee(bmr: Double, activityLevel: ActivityLevel) -> Double {
        (bmr * activityLevel.multiplier).rounded()
    }

    /// Deadline-based: derives exact daily calorie adjustment from the kg-to-change and weeks remaining.
    /// Deficit/surplus are capped at ±1000 kcal/day and the result is floored at 800 kcal for safety.
    static func calorieTarget(tdee: Double, currentWeightKg: Double, goalWeightKg: Double, weeksToDeadline: Double) -> Double {
        guard weeksToDeadline > 0 else { return tdee }
        let kcalPerDay = (goalWeightKg - currentWeightKg) * 7700 / (weeksToDeadline * 7)
        let capped = min(max(kcalPerDay, -1000), 1000)
        return max(800, (tdee + capped).rounded())
    }

    /// Bracket-based fallback when no deadline is set.
    /// Deficit/surplus are capped at 750 kcal to stay safe and sustainable.
    static func calorieTarget(tdee: Double, currentWeightKg: Double, goalWeightKg: Double?) -> Double {
        guard let goal = goalWeightKg, goal > 0 else { return tdee }
        let gap = goal - currentWeightKg
        switch gap {
        case ..<(-5):    return (tdee - 750).rounded()  // aggressive cut (>11 lbs)
        case ..<(-2):    return (tdee - 500).rounded()  // moderate cut (>4.4 lbs)
        case ..<(-0.5):  return (tdee - 250).rounded()  // mild cut
        case (-0.5)...(0.5): return tdee               // at goal
        case ...(5):     return (tdee + 250).rounded()  // mild surplus
        default:         return (tdee + 500).rounded()  // moderate surplus
        }
    }
}
