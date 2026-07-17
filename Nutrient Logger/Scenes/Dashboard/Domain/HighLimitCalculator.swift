//
//  HighLimitCalculator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation

struct HighLimitResult: Equatable {
    let averageAmount: Double
    let percentageOfLimit: Double
}

enum HighLimitCalculator {

    /// Evaluates a nutrient's average daily intake against its upper limit. Averaging mirrors the
    /// "running low" deficiency signal, so a single spike day no longer flags a nutrient as high;
    /// the average across days with data has to clear the limit. Returns nil when there's no
    /// meaningful upper limit to check against (no RDI data, or the "no limit" sentinel), or when
    /// the average is at or below the limit.
    static func evaluate(averageAmount: Double, upperLimit: Double?) -> HighLimitResult? {
        guard let upperLimit, upperLimit > 0, upperLimit < .greatestFiniteMagnitude else { return nil }
        guard averageAmount > upperLimit else { return nil }

        return HighLimitResult(
            averageAmount: averageAmount,
            percentageOfLimit: averageAmount / upperLimit
        )
    }
}
