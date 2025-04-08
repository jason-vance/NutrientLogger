//
//  Potassium_RDIs.swift
//  Potassium_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Potassium_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Potassium_K
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 400,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 860,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 2000,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 2300,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 2500,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 2300,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 3000,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 2300,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 3400,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 2600,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
    }
}
