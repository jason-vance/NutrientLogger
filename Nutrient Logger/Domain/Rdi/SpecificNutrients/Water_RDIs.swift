//
//  Water_RDIs.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import Foundation

class Water_RDIs : AbstractNutrientRdis {
    public init() {
        let nutrientFdcNumber = FdcNutrientGroupMapper.NutrientNumber_Water
        super.init(nutrientFdcNumber)

        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.male,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 3673.5,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
        addLifeStageRdi(LifeStageNutrientRdi.create(
            nutrientFdcNumber: nutrientFdcNumber,
            gender: Gender.female,
            minAgeYears: 19,
            maxAgeYears: Double.greatestFiniteMagnitude,
            recommendedAmount: 2725.5,
            upperLimit: Double.greatestFiniteMagnitude,
            unit: WeightUnit.gram
        ))
    }
}
