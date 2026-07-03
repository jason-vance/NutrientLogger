//
//  WaistUnit.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import Foundation

enum WaistUnit: String, CaseIterable {
    case cm
    case inches = "in"

    var label: String {
        switch self {
        case .cm: return "cm"
        case .inches: return "in"
        }
    }

    func fromCm(_ cm: Double) -> Double {
        switch self {
        case .cm: return cm
        case .inches: return cm / 2.54
        }
    }

    func toCm(_ value: Double) -> Double {
        switch self {
        case .cm: return value
        case .inches: return value * 2.54
        }
    }
}
