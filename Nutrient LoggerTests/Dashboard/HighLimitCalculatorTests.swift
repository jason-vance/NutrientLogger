//
//  HighLimitCalculatorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation
import Testing

struct HighLimitCalculatorTests {

    // MARK: - No qualifying day

    @Test func allDaysUnderLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [100, 150, 200], upperLimit: 300)
        #expect(result == nil)
    }

    @Test func emptyDailyAmountsReturnsNil() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [], upperLimit: 300)
        #expect(result == nil)
    }

    @Test func exactlyAtLimitDoesNotCountAsExceeded() {
        // Only strictly greater-than should count, consistent with the dashed-bar threshold logic.
        let result = HighLimitCalculator.evaluate(dailyAmounts: [300, 300], upperLimit: 300)
        #expect(result == nil)
    }

    // MARK: - No meaningful limit data

    @Test func nilUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [10_000], upperLimit: nil)
        #expect(result == nil)
    }

    @Test func infiniteUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [10_000], upperLimit: .greatestFiniteMagnitude)
        #expect(result == nil)
    }

    @Test func zeroUpperLimitReturnsNil() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [10], upperLimit: 0)
        #expect(result == nil)
    }

    @Test func negativeUpperLimitSentinelReturnsNil() {
        // Guards against the same "-greatestFiniteMagnitude as a sentinel" bug this release
        // fixed for Sodium's recommendedAmount.
        let result = HighLimitCalculator.evaluate(dailyAmounts: [10], upperLimit: -Double.greatestFiniteMagnitude)
        #expect(result == nil)
    }

    // MARK: - Single day exceeded

    @Test func singleDayExceededCounts() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [100, 150, 400], upperLimit: 300)

        #expect(result != nil)
        #expect(result?.daysExceeded == 1)
        #expect(result?.peakAmount == 400)
        #expect(abs((result?.peakPercentageOfLimit ?? 0) - (400.0 / 300.0)) < 0.0001)
    }

    // MARK: - Multiple days exceeded, peak is the worst day

    @Test func multipleDaysExceededTracksPeakAmongExceededDays() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [50, 350, 500, 320], upperLimit: 300)

        #expect(result?.daysExceeded == 3)
        #expect(result?.peakAmount == 500)
    }

    // MARK: - A day well under the limit doesn't dilute the exceeded-day count

    @Test func daysUnderLimitAreExcludedFromCount() {
        let result = HighLimitCalculator.evaluate(dailyAmounts: [0, 0, 0, 0, 0, 0, 301], upperLimit: 300)

        #expect(result?.daysExceeded == 1)
    }
}
