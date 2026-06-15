//
//  AutoMarketingPromptTriggerTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/14/26.
//

import Testing

struct AutoMarketingPromptTriggerTests {

    let today = SimpleDate(rawValue: 20260614)!
    let twentyNineDaysAgo = SimpleDate(rawValue: 20260516)!
    let thirtyDaysAgo = SimpleDate(rawValue: 20260515)!

    @Test func testDoesNotShowWhenNotAFullLoggingDay() throws {
        let shouldShow = AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: false,
            isSubscribed: false,
            lastShownDate: nil,
            today: today
        )

        #expect(!shouldShow)
    }

    @Test func testDoesNotShowWhenAlreadySubscribed() throws {
        let shouldShow = AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: true,
            isSubscribed: true,
            lastShownDate: nil,
            today: today
        )

        #expect(!shouldShow)
    }

    @Test func testShowsOnFirstFullLoggingDayWhenNeverShownBefore() throws {
        let shouldShow = AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: true,
            isSubscribed: false,
            lastShownDate: nil,
            today: today
        )

        #expect(shouldShow)
    }

    @Test func testDoesNotShowAgainBeforeThirtyDaysHavePassed() throws {
        let shouldShow = AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: true,
            isSubscribed: false,
            lastShownDate: twentyNineDaysAgo,
            today: today
        )

        #expect(!shouldShow)
    }

    @Test func testShowsAgainOnceThirtyDaysHavePassed() throws {
        let shouldShow = AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: true,
            isSubscribed: false,
            lastShownDate: thirtyDaysAgo,
            today: today
        )

        #expect(shouldShow)
    }
}
