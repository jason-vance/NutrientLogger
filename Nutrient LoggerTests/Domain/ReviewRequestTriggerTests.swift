//
//  ReviewRequestTriggerTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct ReviewRequestTriggerTests {

    private let today = SimpleDate(year: 2026, month: 11, day: 6)!

    private func shouldRequest(
        streak: Int = 7,
        fullDay: Bool = true,
        lastRequested: SimpleDate? = nil,
        optedOut: Bool = false
    ) -> Bool {
        ReviewRequestTrigger.shouldRequest(
            streakCount: streak,
            isFullLoggingDay: fullDay,
            lastRequestedDate: lastRequested,
            hasOptedOut: optedOut,
            today: today
        )
    }

    @Test func asksAfterAFullLoggedWeek() {
        #expect(shouldRequest(streak: 7))
        #expect(shouldRequest(streak: 30))
    }

    @Test func waitsForAWeekOfLogging() {
        #expect(!shouldRequest(streak: 6))
        #expect(!shouldRequest(streak: 0))
    }

    @Test func waitsForAFullDay() {
        #expect(!shouldRequest(fullDay: false))
    }

    @Test func spacesRequestsOut() {
        #expect(!shouldRequest(lastRequested: today))
        #expect(!shouldRequest(lastRequested: today.adding(days: -119)))
        #expect(shouldRequest(lastRequested: today.adding(days: -120)))
    }

    @Test func respectsAnEarlierOptOut() {
        #expect(!shouldRequest(optedOut: true))
    }
}
