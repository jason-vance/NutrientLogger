//
//  Omega3ALA_RDIs.swift
//  Omega3ALA_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Omega3ALA_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 0.7,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 0.9,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 1.2,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 1,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 14,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 1.6,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 14,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 1.1,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
    }
}
