//
//  NutrientCoverage.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Not every USDA food reports every nutrient. The survey foods most people log have no
/// pantothenic acid or manganese data at all, so a day of steak and eggs would read 0% and get
/// called a gap. A nutrient only counts as low when enough of what was eaten actually reports it.
enum NutrientCoverage {

    /// Share of the logged food weight that has to report a nutrient before its total is trusted.
    static let minimumShare = 0.5

    static func isMeasured(reportedGrams: Double, totalGrams: Double) -> Bool {
        guard totalGrams > 0 else { return false }
        return reportedGrams / totalGrams >= minimumShare
    }
}
