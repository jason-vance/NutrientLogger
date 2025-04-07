//
//  Manganese_RDIs.swift
//  Manganese_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

public class Manganese_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 0.003,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 0.6,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 1.2,
            upperLimit: 2,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 1.5,
            upperLimit: 3,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 1.9,
            upperLimit: 6,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 1.6,
            upperLimit: 6,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 2.2,
            upperLimit: 9,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 1.6,
            upperLimit: 9,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 2.3,
            upperLimit: 11,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 1.8,
            upperLimit: 11,
            unit: WeightUnit.milligram
        ))
    }
}
