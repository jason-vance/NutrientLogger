//
//  NotificationPlannerTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/14/26.
//

import Testing
import Foundation

struct NotificationPlannerTests {

    // 2026-06-14, a Sunday
    let morning = Date.from(year: 2026, month: 6, day: 14, hr: 9, min: 0)
    let afternoon = Date.from(year: 2026, month: 6, day: 14, hr: 14, min: 0)
    let lateNight = Date.from(year: 2026, month: 6, day: 14, hr: 22, min: 0)

    let reminderTime8pm = Date.from(year: 2026, month: 6, day: 14, hr: 20, min: 0)
    let reminderTime8pmTomorrow = Date.from(year: 2026, month: 6, day: 15, hr: 20, min: 0)
    let riskTime9pm = Date.from(year: 2026, month: 6, day: 14, hr: 21, min: 0)

    // MARK: - Daily Reminder

    @Test func testNoDailyReminderWhenDisabled() throws {
        let plan = NotificationPlanner.plan(
            now: morning,
            loggedSinceNoonToday: false,
            loggedAnythingToday: false,
            streakCount: 0,
            dailyReminderEnabled: false,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.dailyReminderFireDate == nil)
    }

    @Test func testDailyReminderScheduledForTodayWhenBeforeReminderTimeAndNothingLoggedSinceNoon() throws {
        let plan = NotificationPlanner.plan(
            now: afternoon,
            loggedSinceNoonToday: false,
            loggedAnythingToday: true,
            streakCount: 0,
            dailyReminderEnabled: true,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.dailyReminderFireDate == reminderTime8pm)
    }

    @Test func testDailyReminderNotScheduledWhenAlreadyLoggedSinceNoon() throws {
        let plan = NotificationPlanner.plan(
            now: afternoon,
            loggedSinceNoonToday: true,
            loggedAnythingToday: true,
            streakCount: 0,
            dailyReminderEnabled: true,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.dailyReminderFireDate == nil)
    }

    @Test func testDailyReminderRolledOverToTomorrowWhenReminderTimeAlreadyPassed() throws {
        let plan = NotificationPlanner.plan(
            now: lateNight,
            loggedSinceNoonToday: false,
            loggedAnythingToday: false,
            streakCount: 0,
            dailyReminderEnabled: true,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.dailyReminderFireDate == reminderTime8pmTomorrow)
    }

    @Test func testDailyReminderBeforeNoonIgnoresLoggedSinceNoonFlag() throws {
        let plan = NotificationPlanner.plan(
            now: morning,
            loggedSinceNoonToday: false,
            loggedAnythingToday: true,
            streakCount: 0,
            dailyReminderEnabled: true,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.dailyReminderFireDate == reminderTime8pm)
    }

    // MARK: - Streak At Risk

    @Test func testNoStreakAtRiskNotificationWhenStreakAtThreshold() throws {
        let plan = NotificationPlanner.plan(
            now: morning,
            loggedSinceNoonToday: false,
            loggedAnythingToday: false,
            streakCount: 3,
            dailyReminderEnabled: false,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.streakAtRiskFireDate == nil)
    }

    @Test func testNoStreakAtRiskNotificationWhenAlreadyLoggedToday() throws {
        let plan = NotificationPlanner.plan(
            now: morning,
            loggedSinceNoonToday: false,
            loggedAnythingToday: true,
            streakCount: 5,
            dailyReminderEnabled: false,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.streakAtRiskFireDate == nil)
    }

    @Test func testStreakAtRiskScheduledFor9pmWhenStreakAboveThresholdAndNothingLoggedToday() throws {
        let plan = NotificationPlanner.plan(
            now: morning,
            loggedSinceNoonToday: false,
            loggedAnythingToday: false,
            streakCount: 5,
            dailyReminderEnabled: false,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.streakAtRiskFireDate == riskTime9pm)
        #expect(plan.streakCount == 5)
    }

    @Test func testNoStreakAtRiskNotificationWhenRiskTimeAlreadyPassed() throws {
        let plan = NotificationPlanner.plan(
            now: lateNight,
            loggedSinceNoonToday: false,
            loggedAnythingToday: false,
            streakCount: 5,
            dailyReminderEnabled: false,
            dailyReminderHour: 20,
            dailyReminderMinute: 0
        )

        #expect(plan.streakAtRiskFireDate == nil)
    }
}
