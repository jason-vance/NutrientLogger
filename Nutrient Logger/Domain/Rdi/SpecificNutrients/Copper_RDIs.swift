//
//  Copper_RDIs.swift
//  Copper_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Copper_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Copper_Cu
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 200,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 200,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 340,
            upperLimit: 1000,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 440,
            upperLimit: 3000,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 700,
            upperLimit: 5000,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 890,
            upperLimit: 8000,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 900,
            upperLimit: 10000,
            unit: WeightUnit.microgram
        ))
    }
}
