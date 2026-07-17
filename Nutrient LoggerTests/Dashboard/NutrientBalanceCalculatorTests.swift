//
//  NutrientBalanceCalculatorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/17/26.
//

import Foundation
import Testing

struct NutrientBalanceCalculatorTests {

    private func ratio(
        min: Double? = nil,
        max: Double? = nil,
        numerator: [String] = ["A"],
        denominator: [String] = ["B"]
    ) -> NutrientRatio {
        NutrientRatio(
            id: "test",
            name: "A : B",
            numeratorLabel: "A",
            denominatorLabel: "B",
            numeratorNutrientIds: numerator,
            denominatorNutrientIds: denominator,
            healthyMax: max,
            healthyMin: min,
            explanation: "",
            isBuiltIn: false
        )
    }

    // MARK: - Upper bound

    @Test func ratioAboveMaxIsFlaggedTooHigh() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["A": 2.0, "B": 1.0]
        )
        #expect(result?.isTooHigh == true)
        #expect(result?.isTooLow == false)
        #expect(abs((result?.ratio ?? 0) - 2.0) < 0.0001)
    }

    @Test func ratioAtMaxIsNotFlagged() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["A": 1.0, "B": 1.0]
        )
        #expect(result == nil)
    }

    // MARK: - Lower bound

    @Test func ratioBelowMinIsFlaggedTooLow() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(min: 0.5),
            gramsByNutrient: ["A": 1.0, "B": 4.0] // ratio 0.25
        )
        #expect(result?.isTooLow == true)
        #expect(result?.isTooHigh == false)
    }

    // MARK: - Band (both bounds)

    @Test func ratioInsideBandIsNotFlagged() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(min: 1.5, max: 3.0),
            gramsByNutrient: ["A": 2.0, "B": 1.0] // ratio 2.0
        )
        #expect(result == nil)
    }

    @Test func ratioAboveBandFlagsHigh() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(min: 1.5, max: 3.0),
            gramsByNutrient: ["A": 4.0, "B": 1.0]
        )
        #expect(result?.isTooHigh == true)
    }

    // MARK: - Missing data

    @Test func missingDenominatorReturnsNil() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["A": 2.0]
        )
        #expect(result == nil)
    }

    @Test func missingNumeratorReturnsNil() {
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["B": 2.0]
        )
        #expect(result == nil)
    }

    // MARK: - Multi-nutrient sides sum together

    @Test func numeratorAndDenominatorSumTheirNutrients() {
        // Numerator A+B = 6, denominator C+D = 2 → ratio 3.0
        let result = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 2.0, numerator: ["A", "B"], denominator: ["C", "D"]),
            gramsByNutrient: ["A": 4.0, "B": 2.0, "C": 1.5, "D": 0.5]
        )
        #expect(abs((result?.ratio ?? 0) - 3.0) < 0.0001)
        #expect(result?.isTooHigh == true)
    }

    // MARK: - Severity

    @Test func severityGrowsWithDistanceFromBand() {
        let mild = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["A": 1.5, "B": 1.0]
        )
        let severe = NutrientBalanceCalculator.evaluate(
            ratio: ratio(max: 1.0),
            gramsByNutrient: ["A": 5.0, "B": 1.0]
        )
        #expect((severe?.severity ?? 0) > (mild?.severity ?? 0))
    }
}
