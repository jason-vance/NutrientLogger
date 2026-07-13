//
//  Sodium_RDIs.swift
//  Sodium_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Sodium_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Sodium_Na
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 800,
            upperLimit: 1000,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 1000,
            upperLimit: 1500,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 1200,
            upperLimit: 1800,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 14,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 1500,
            upperLimit: 2300,
            unit: WeightUnit.milligram
        ))
    }
}
