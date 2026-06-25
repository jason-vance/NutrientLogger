//
//  BodyWeightUnit.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import Foundation

enum BodyWeightUnit: String, CaseIterable {
    case lbs
    case kg

    private static let kgToLbs = 2.20462

    var label: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }

    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lbs: return kg * Self.kgToLbs
        }
    }

    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lbs: return value / Self.kgToLbs
        }
    }
}
