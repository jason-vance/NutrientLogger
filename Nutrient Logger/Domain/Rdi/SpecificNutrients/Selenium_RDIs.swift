//
//  Selenium_RDIs.swift
//  Selenium_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

class Selenium_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Selenium_Se
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 15,
            upperLimit: 45,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 20,
            upperLimit: 60,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 20,
            upperLimit: 90,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 30,
            upperLimit: 150,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 40,
            upperLimit: 280,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 14,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 55,
            upperLimit: 400,
            unit: WeightUnit.microgram
        ))
    }
}
