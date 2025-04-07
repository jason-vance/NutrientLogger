//
//  WeightUnit.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public struct WeightUnit: Hashable, Equatable {
    private static let unknownName = "?"
    private static let unknownGramAmount = 0.0

    private static let caloriesName = "cal"
    private static let caloriesNameAlt = "kcal"
    private static let caloriesGramAmount = 1.0

    private static let kilojoulesName = "kj"
    private static let kilojoulesGramAmount = 1.0

    private static let gramName = "g"
    private static let gramGramAmount = 1.0

    private static let milligramName = "mg"
    private static let milligramGramAmount = gramGramAmount / 1000.0

    private static let microgramName = "μg"
    private static let microgramNameAlt = "ug"
    private static let microgramGramAmount = milligramGramAmount / 1000.0

    private static let iUName = "iu"
    private static let vitaminAIUGramAmount = microgramGramAmount / 3.33333333
    private static let vitaminDIUGramAmount = microgramGramAmount / 40

    public static let unknown = WeightUnit(unknownName, unknownGramAmount)
    public static let calories = WeightUnit(caloriesName, caloriesGramAmount)
    public static let kilojoules = WeightUnit(kilojoulesName, kilojoulesGramAmount)
    public static let gram = WeightUnit(gramName, gramGramAmount)
    public static let milligram = WeightUnit(milligramName, milligramGramAmount)
    public static let microgram = WeightUnit(microgramName, microgramGramAmount)
    public static let vitaminA_IU = WeightUnit(iUName, vitaminAIUGramAmount)
    public static let vitaminD_IU = WeightUnit(iUName, vitaminDIUGramAmount)

    public let name: String
    public let gramAmount: Double
    
    private init(_ name: String, _ gramAmount: Double) {
        self.name = name
        self.gramAmount = gramAmount
    }

    public static func unitFrom(_ nutrient: Nutrient) -> WeightUnit {
        let unitStr = nutrient.unitName
        let fdcNumber = nutrient.fdcNumber
        return unitFrom(unitStr, fdcNumber)
    }

    public static func unitFrom(_ unitStr: String, _ fdcNumber: String) -> WeightUnit {
        if (gramName.caseInsensitiveCompare(unitStr) == .orderedSame) { return gram }
        if (milligramName.caseInsensitiveCompare(unitStr) == .orderedSame) { return milligram }
        if (microgramName.caseInsensitiveCompare(unitStr) == .orderedSame) { return microgram }
        if (microgramNameAlt.caseInsensitiveCompare(unitStr) == .orderedSame) { return microgram }
        if (caloriesName.caseInsensitiveCompare(unitStr) == .orderedSame) { return calories }
        if (caloriesNameAlt.caseInsensitiveCompare(unitStr) == .orderedSame) { return calories }
        if (kilojoulesName.caseInsensitiveCompare(unitStr) == .orderedSame) { return kilojoules }
        if (fdcNumber == FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU) { return vitaminA_IU }
        if (fdcNumber == FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU) { return vitaminD_IU }

        return unknown
    }

    public func convertTo(_ toUnit: WeightUnit, _ amount: Double) -> Double {
        if (self == WeightUnit.unknown || toUnit == WeightUnit.unknown) {
            return 0
        }

        if (self == WeightUnit.calories && toUnit != WeightUnit.calories) {
            return 0
        }

        if (self == WeightUnit.kilojoules && toUnit != WeightUnit.kilojoules) {
            return 0
        }

        let rv = amount / (toUnit.gramAmount / gramAmount)
        return rv
    }
}
