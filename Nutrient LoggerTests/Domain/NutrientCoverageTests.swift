//
//  NutrientCoverageTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct NutrientCoverageTests {

    @Test func trustsANutrientMostOfTheFoodReports() {
        #expect(NutrientCoverage.isMeasured(reportedGrams: 600, totalGrams: 800))
        #expect(NutrientCoverage.isMeasured(reportedGrams: 400, totalGrams: 800))
    }

    @Test func doesNotCallUnreportedNutrientsLow() {
        // A day of survey foods, none of which report manganese.
        #expect(!NutrientCoverage.isMeasured(reportedGrams: 0, totalGrams: 950))
        #expect(!NutrientCoverage.isMeasured(reportedGrams: 100, totalGrams: 950))
        #expect(!NutrientCoverage.isMeasured(reportedGrams: 0, totalGrams: 0))
    }
}
