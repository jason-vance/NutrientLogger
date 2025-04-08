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
            recommendedAmount: -Double.greatestFiniteMagnitude,
            upperLimit: 1000,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: -Double.greatestFiniteMagnitude,
            upperLimit: 1200,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 51,
            recommendedAmount: -Double.greatestFiniteMagnitude,
            upperLimit: 1500,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 51,
            maxAgeYears: 71,
            recommendedAmount: -Double.greatestFiniteMagnitude,
            upperLimit: 1300,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 71,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: -Double.greatestFiniteMagnitude,
            upperLimit: 1200,
            unit: WeightUnit.milligram
        ))
    }
}
