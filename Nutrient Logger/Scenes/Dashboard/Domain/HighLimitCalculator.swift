//
//  HighLimitCalculator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation

struct HighLimitResult: Equatable {
    let daysExceeded: Int
    let peakAmount: Double
    let peakPercentageOfLimit: Double
}

enum HighLimitCalculator {

    /// Evaluates one nutrient's daily intake amounts against its upper limit. Returns nil when
    /// there's no meaningful upper limit to check against (no RDI data, or the "no limit"
    /// sentinel), or when no day in the range exceeded it.
    static func evaluate(dailyAmounts: [Double], upperLimit: Double?) -> HighLimitResult? {
        guard let upperLimit, upperLimit > 0, upperLimit < .greatestFiniteMagnitude else { return nil }

        let exceededDays = dailyAmounts.filter { $0 > upperLimit }
        guard let peak = exceededDays.max() else { return nil }

        return HighLimitResult(
            daysExceeded: exceededDays.count,
            peakAmount: peak,
            peakPercentageOfLimit: peak / upperLimit
        )
    }
}
