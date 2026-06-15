//
//  NotificationSettings.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

/// `UserDefaults` keys and defaults for the "habit loop" notification settings, shared between
/// the settings UI (`UserProfileView`) and `NotificationCoordinator`.
enum NotificationSettings {
    static let dailyReminderEnabledKey = "dailyReminderEnabled"
    static let dailyReminderHourKey = "dailyReminderHour"
    static let dailyReminderMinuteKey = "dailyReminderMinute"

    static let defaultDailyReminderEnabled = true
    static let defaultDailyReminderHour = 20
    static let defaultDailyReminderMinute = 0
}
