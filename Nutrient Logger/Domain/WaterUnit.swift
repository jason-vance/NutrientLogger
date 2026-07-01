//
//  WaterUnit.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import Foundation

enum WaterUnit: String, CaseIterable, Identifiable {
    case cups = "cups"
    case floz = "fl oz"
    case mL = "mL"

    var id: String { rawValue }

    static let appStorageKey = "preferredWaterUnit"

    private static let gramsPerCup: Double = 237
    private static let gramsPerFloz: Double = 29.5735

    func fromGrams(_ grams: Double) -> Double {
        switch self {
        case .cups: return grams / Self.gramsPerCup
        case .floz: return grams / Self.gramsPerFloz
        case .mL: return grams
        }
    }

    func toGrams(_ amount: Double) -> Double {
        switch self {
        case .cups: return amount * Self.gramsPerCup
        case .floz: return amount * Self.gramsPerFloz
        case .mL: return amount
        }
    }

    var quickLogAmounts: [(label: String, grams: Double)] {
        switch self {
        case .cups:  return [("1 cup", 237), ("2 cups", 474), ("4 cups", 946)]
        case .floz:  return [("8 fl oz", 237), ("16 fl oz", 473), ("32 fl oz", 946)]
        case .mL:    return [("250 mL", 250), ("500 mL", 500), ("1000 mL", 1000)]
        }
    }

    func formatted(_ grams: Double) -> String {
        let amount = fromGrams(grams)
        switch self {
        case .cups: return "\(amount.formatted(maxDigits: 1))"
        case .floz: return "\(amount.formatted(maxDigits: 0))"
        case .mL:   return "\(amount.formatted(maxDigits: 0))"
        }
    }

    func defaultGoalGrams(gender: Gender) -> Double {
        switch gender {
        case .male:             return 3700
        case .female, .unknown: return 2750
        }
    }
}
