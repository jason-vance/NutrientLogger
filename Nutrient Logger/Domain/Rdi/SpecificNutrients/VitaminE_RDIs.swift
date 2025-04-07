//
//  VitaminE_RDIs.swift
//  VitaminE_RDIs
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

public class VitaminE_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0,
            maxAgeYears: 0.5833333,
            recommendedAmount: 4,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 0.5833333,
            maxAgeYears: 1,
            recommendedAmount: 5,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 1,
            maxAgeYears: 4,
            recommendedAmount: 6,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 4,
            maxAgeYears: 9,
            recommendedAmount: 7,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 9,
            maxAgeYears: 14,
            recommendedAmount: 11,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.unknown,
            minAgeYears: 14,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 15,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.milligram
        ))
    }
}
