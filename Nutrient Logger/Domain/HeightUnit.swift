//
//  HeightUnit.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import Foundation

enum HeightUnit: String, CaseIterable {
    case ftIn
    case cm

    private static let cmToInches = 0.393701

    var label: String {
        switch self {
        case .ftIn: return "ft/in"
        case .cm: return "cm"
        }
    }

    /// Formats a height (stored in cm) using this unit's measurement system:
    /// feet/inches for `.ftIn`, whole centimeters for `.cm`.
    func formattedHeight(cm: Double) -> String {
        switch self {
        case .cm:
            return "\(cm.formatted(maxDigits: 0)) cm"
        case .ftIn:
            let totalInches = Int((cm * Self.cmToInches).rounded())
            let feet = totalInches / 12
            let inches = totalInches % 12
            return "\(feet)'\(inches)\""
        }
    }

    func heightToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) / Self.cmToInches
    }
}
