//
//  NotificationPlanner.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

/// Computes which "habit loop" notifications should be scheduled, given the user's current
/// logging activity and notification settings.
///
/// Because this is an offline app with only local notifications, there's no way to evaluate
/// these conditions at the moment a notification would fire. Instead, the plan is recomputed
/// (and pending notifications rescheduled) whenever the app backgrounds or logging activity
/// changes, so the schedule always reflects the latest known state.
enum NotificationPlanner {

    struct Plan: Equatable {
        var dailyReminderFireDate: Date?
        var streakAtRiskFireDate: Date?
        var streakCount: Int
    }

    /// The streak must exceed this many days before a "streak at risk" notification is relevant.
    static let streakAtRiskThreshold = 3

    /// The hour (24-hour clock) at which the "streak at risk" notification fires, if needed.
    static let streakAtRiskHour = 21

    /// The hour after which "logged since noon" is evaluated for the daily reminder.
    static let dailyReminderEvaluationHour = 12

    static func plan(
        now: Date,
        loggedSinceNoonToday: Bool,
        loggedAnythingToday: Bool,
        streakCount: Int,
        dailyReminderEnabled: Bool,
        dailyReminderHour: Int,
        dailyReminderMinute: Int,
        streakWarningEnabled: Bool = true,
        calendar: Calendar = .current
    ) -> Plan {
        Plan(
            dailyReminderFireDate: dailyReminderFireDate(
                now: now,
                loggedSinceNoonToday: loggedSinceNoonToday,
                enabled: dailyReminderEnabled,
                hour: dailyReminderHour,
                minute: dailyReminderMinute,
                calendar: calendar
            ),
            streakAtRiskFireDate: streakAtRiskFireDate(
                now: now,
                loggedAnythingToday: loggedAnythingToday,
                streakCount: streakCount,
                enabled: streakWarningEnabled,
                calendar: calendar
            ),
            streakCount: streakCount
        )
    }

    /// Fires at the user's chosen time if nothing has been logged since noon today. If that time
    /// has already passed for today, schedules (provisionally) for tomorrow - the next reschedule
    /// will correct or cancel it based on tomorrow's activity.
    private static func dailyReminderFireDate(
        now: Date,
        loggedSinceNoonToday: Bool,
        enabled: Bool,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date? {
        guard enabled else { return nil }
        guard let reminderTimeToday = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else {
            return nil
        }

        if now < reminderTimeToday {
            return loggedSinceNoonToday ? nil : reminderTimeToday
        }

        return calendar.date(byAdding: .day, value: 1, to: reminderTimeToday)
    }

    /// Fires at `streakAtRiskHour` today if the streak is long enough to be worth protecting and
    /// nothing has been logged yet today. Never scheduled for a time that has already passed.
    private static func streakAtRiskFireDate(
        now: Date,
        loggedAnythingToday: Bool,
        streakCount: Int,
        enabled: Bool,
        calendar: Calendar
    ) -> Date? {
        guard enabled, streakCount > streakAtRiskThreshold, !loggedAnythingToday else { return nil }
        guard let riskTimeToday = calendar.date(bySettingHour: streakAtRiskHour, minute: 0, second: 0, of: now) else {
            return nil
        }

        return now < riskTimeToday ? riskTimeToday : nil
    }
}
