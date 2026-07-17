//
//  HighLimitCalculatorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation
import Testing

struct HighLimitCalculatorTests {

    // MARK: - Average at or below the limit

    @Test func averageUnderLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(averageAmount: 200, upperLimit: 300)
        #expect(result == nil)
    }

    @Test func averageExactlyAtLimitReturnsNil() {
        // Only strictly greater-than should count, consistent with the dashed-bar threshold logic.
        let result = HighLimitCalculator.evaluate(averageAmount: 300, upperLimit: 300)
        #expect(result == nil)
    }

    @Test func zeroAverageReturnsNil() {
        let result = HighLimitCalculator.evaluate(averageAmount: 0, upperLimit: 300)
        #expect(result == nil)
    }

    // MARK: - No meaningful limit data

    @Test func nilUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(averageAmount: 10_000, upperLimit: nil)
        #expect(result == nil)
    }

    @Test func infiniteUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(averageAmount: 10_000, upperLimit: .greatestFiniteMagnitude)
        #expect(result == nil)
    }

    @Test func zeroUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(averageAmount: 10, upperLimit: 0)
        #expect(result == nil)
    }

    @Test func negativeUpperLimitSentinelReturnsNil() {
        // Guards against the same "-greatestFiniteMagnitude as a sentinel" bug this release
        // fixed for Sodium's recommendedAmount.
        let result = HighLimitCalculator.evaluate(averageAmount: 10, upperLimit: -Double.greatestFiniteMagnitude)
        #expect(result == nil)
    }

    // MARK: - Average over the limit

    @Test func averageOverLimitIsFlagged() {
        let result = HighLimitCalculator.evaluate(averageAmount: 400, upperLimit: 300)

        #expect(result != nil)
        #expect(result?.averageAmount == 400)
        #expect(abs((result?.percentageOfLimit ?? 0) - (400.0 / 300.0)) < 0.0001)
    }

    // MARK: - A single spike day no longer flags a nutrient once averaged down

    @Test func singleSpikeThatAveragesUnderLimitReturnsNil() {
        // 500 on one day but 50 on three others → average 162.5, under the 300 limit.
        let dailyAmounts = [50.0, 50.0, 50.0, 500.0]
        let average = dailyAmounts.reduce(0, +) / Double(dailyAmounts.count)
        let result = HighLimitCalculator.evaluate(averageAmount: average, upperLimit: 300)
        #expect(result == nil)
    }
}
