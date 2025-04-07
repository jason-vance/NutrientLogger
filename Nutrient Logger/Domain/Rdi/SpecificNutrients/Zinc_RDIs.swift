//
//  Zinc_RDIs.swift
//  Zinc_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

public class Zinc_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 2,
            upperLimit: 4,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 3,
            upperLimit: 5,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 3,
            upperLimit: 7,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 5,
            upperLimit: 12,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 8,
            upperLimit: 23,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 11,
            upperLimit: 34,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 9,
            upperLimit: 34,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 11,
            upperLimit: 40,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 8,
            upperLimit: 40,
            unit: WeightUnit.milligram
        ))
    }
}
