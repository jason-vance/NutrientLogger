//
//  GoalProgressBarLayoutTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/13/26.
//

import Foundation
import Testing

struct GoalProgressBarLayoutTests {

    // MARK: - Below goal, no exceeded state

    @Test func belowGoalFillsProportionally() {
        let layout = GoalProgressBarLayout.compute(amount: 40, goal: 100, dashedThreshold: 100)

        #expect(layout.solidFraction == 0.4)
        #expect(layout.excessFraction == 0)
        #expect(layout.isExceeded == false)
    }

    @Test func atGoalFillsCompletelyWithoutExceeding() {
        let layout = GoalProgressBarLayout.compute(amount: 100, goal: 100, dashedThreshold: 100)

        #expect(layout.solidFraction == 1.0)
        #expect(layout.isExceeded == false)
    }

    // MARK: - Macro case: dashedThreshold == goal, so any overage triggers the split

    @Test func overGoalWithSameDashedThresholdSplitsProportionally() {
        let layout = GoalProgressBarLayout.compute(amount: 150, goal: 100, dashedThreshold: 100)

        #expect(layout.isExceeded == true)
        #expect(abs(layout.solidFraction - (100.0 / 150.0)) < 0.0001)
        #expect(abs(layout.excessFraction - (50.0 / 150.0)) < 0.0001)
        #expect(abs((layout.solidFraction + layout.excessFraction) - 1.0) < 0.0001)
    }

    // MARK: - Vitamin/mineral case: goal (RDA) and dashedThreshold (upper limit) differ

    @Test func overGoalButUnderUpperLimitStaysFullyCappedWithoutExceeding() {
        // 150% of RDA, but nowhere near the (much higher) upper limit — should read as
        // fully solid, not exceeded, since dashed styling is reserved for the UL crossing.
        let layout = GoalProgressBarLayout.compute(amount: 150, goal: 100, dashedThreshold: 400)

        #expect(layout.solidFraction == 1.0)
        #expect(layout.excessFraction == 0)
        #expect(layout.isExceeded == false)
    }

    @Test func overUpperLimitSplitsProportionallyToUpperLimit() {
        let layout = GoalProgressBarLayout.compute(amount: 500, goal: 100, dashedThreshold: 400)

        #expect(layout.isExceeded == true)
        #expect(abs(layout.solidFraction - (400.0 / 500.0)) < 0.0001)
        #expect(abs(layout.excessFraction - (100.0 / 500.0)) < 0.0001)
    }

    @Test func exactlyAtUpperLimitDoesNotTriggerExceeded() {
        let layout = GoalProgressBarLayout.compute(amount: 400, goal: 100, dashedThreshold: 400)

        #expect(layout.isExceeded == false)
        #expect(layout.solidFraction == 1.0)
    }

    // MARK: - No upper limit data (nil or sentinel "no limit" value)

    @Test func nilDashedThresholdNeverExceeds() {
        let layout = GoalProgressBarLayout.compute(amount: 10_000, goal: 100, dashedThreshold: nil)

        #expect(layout.isExceeded == false)
        #expect(layout.solidFraction == 1.0)
    }

    @Test func infiniteDashedThresholdNeverExceeds() {
        let layout = GoalProgressBarLayout.compute(amount: 10_000, goal: 100, dashedThreshold: .greatestFiniteMagnitude)

        #expect(layout.isExceeded == false)
        #expect(layout.solidFraction == 1.0)
    }

    // MARK: - Edge cases

    @Test func zeroGoalWithNoDashedThresholdProducesEmptyBar() {
        let layout = GoalProgressBarLayout.compute(amount: 50, goal: 0, dashedThreshold: nil)

        #expect(layout.solidFraction == 0)
        #expect(layout.isExceeded == false)
    }

    @Test func zeroAmountProducesEmptyBar() {
        let layout = GoalProgressBarLayout.compute(amount: 0, goal: 100, dashedThreshold: 400)

        #expect(layout.solidFraction == 0)
        #expect(layout.isExceeded == false)
    }

    @Test func negativeDashedThresholdIsTreatedAsNoLimit() {
        // Guards against the same "-greatestFiniteMagnitude as a sentinel" bug this release
        // fixed for Sodium's recommendedAmount — dashedThreshold should never legitimately be
        // negative, but the layout math shouldn't treat it as "already exceeded" if it is.
        let layout = GoalProgressBarLayout.compute(amount: 50, goal: 100, dashedThreshold: -Double.greatestFiniteMagnitude)

        #expect(layout.isExceeded == false)
        #expect(layout.solidFraction == 0.5)
    }
}
