//
//  LifeStageNutrientRdi.swift
//  LifeStageNutrientRdi
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation

class LifeStageNutrientRdi {
    private let secondsInYear = 365.0 * 86400.0

    public var nutrientFdcNumber: String = ""
    public var gender: Gender = Gender.unknown
    public var minAgeYears: Double = 0.0
    public var maxAgeYears: Double = Double.greatestFiniteMagnitude
    public var recommendedAmount: Double = 0.0
    public var upperLimit: Double = Double.greatestFiniteMagnitude
    public var unit: WeightUnit = WeightUnit.unknown
    
    public static func create(nutrientFdcNumber: String, gender:Gender, minAgeYears: Double, maxAgeYears: Double, recommendedAmount: Double, upperLimit: Double, unit: WeightUnit) -> LifeStageNutrientRdi {
        let rdi = LifeStageNutrientRdi()
        rdi.nutrientFdcNumber = nutrientFdcNumber
        rdi.gender = gender
        rdi.minAgeYears = minAgeYears
        rdi.maxAgeYears = maxAgeYears
        rdi.recommendedAmount = recommendedAmount
        rdi.upperLimit = upperLimit
        rdi.unit = unit
        return rdi
    }

    public func appliesTo(_ nutrientNumber: String) -> Bool {
        return nutrientFdcNumber == nutrientNumber
    }

    public func matches(_ gender: Gender, _ ageSeconds: TimeInterval) -> Bool {
        return genderMatches(gender) && ageMatches(ageSeconds)
    }

    private func genderMatches(_ gender: Gender) -> Bool {
        if (self.gender == Gender.unknown) {
            return true
        }
        if (gender == Gender.unknown) {
            return true
        }
        return self.gender == gender
    }

    private func ageMatches(_ ageSeconds: TimeInterval) -> Bool {
        let ageYears = ageSeconds / secondsInYear
        return (ageYears >= minAgeYears && ageYears < maxAgeYears && ageYears < 1000)
    }
}
