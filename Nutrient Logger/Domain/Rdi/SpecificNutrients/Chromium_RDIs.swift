//
//  Chromium_RDIs.swift
//  Chromium_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Chromium_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 0.2,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 5.5,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 11,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 15,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 25,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 21,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 35,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 24,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 19,
            maxAgeYears: 51,
            recommendedAmount: 35,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 19,
            maxAgeYears: 51,
            recommendedAmount: 25,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 51,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 30,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 51,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 20,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
    }
}
