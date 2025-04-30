//
//  DoubleExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import Foundation

public extension Double {
    
    static let cardShadowColorOpacity: Double = 0.5
    static let cardBackgroundColorOpacity: Double = 0.1

    func toRadians() -> Double {
        return self * .pi / 180
    }
    
    func formatted(maxDigits: Int = 10, minDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = maxDigits
        formatter.minimumFractionDigits = minDigits
        return formatter.string(from: NSNumber(value: self))!
    }
}

