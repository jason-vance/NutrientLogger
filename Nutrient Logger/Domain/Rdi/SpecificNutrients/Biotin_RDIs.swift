//
//  Biotin_RDIs.swift
//  Biotin_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

public class Biotin_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Biotin
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 5,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 6,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 8,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 12,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 20,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 14,
            maxAgeYears: 19,
            recommendedAmount: 25,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 30,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.microgram
        ))
    }
}
