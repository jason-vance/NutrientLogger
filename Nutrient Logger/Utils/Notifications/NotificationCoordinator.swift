//
//  NotificationCoordinator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation
import SwiftData

/// Recomputes and applies the daily reminder / streak-at-risk notification schedule based on
/// today's logging activity, the current streak, and the user's notification settings.
@MainActor
enum NotificationCoordinator {

    static func reschedule(modelContext: ModelContext) {
        let today = SimpleDate.today
        let descriptor = FetchDescriptor<ConsumedFood>(
            predicate: #Predicate { $0.dateLogged == today }
        )
        let todaysFoods = (try? modelContext.fetch(descriptor)) ?? []

        let streak = LoggingStreakStore().load()

        let now = Date.now
        let calendar = Calendar.current
        let noon = calendar.date(
            bySettingHour: NotificationPlanner.dailyReminderEvaluationHour,
            minute: 0,
            second: 0,
            of: now
        ) ?? now

        let defaults = UserDefaults.standard
        let plan = NotificationPlanner.plan(
            now: now,
            loggedSinceNoonToday: todaysFoods.contains { $0.created >= noon },
            loggedAnythingToday: !todaysFoods.isEmpty,
            streakCount: streak.count,
            dailyReminderEnabled: defaults.object(forKey: NotificationSettings.dailyReminderEnabledKey) as? Bool
                ?? NotificationSettings.defaultDailyReminderEnabled,
            dailyReminderHour: defaults.object(forKey: NotificationSettings.dailyReminderHourKey) as? Int
                ?? NotificationSettings.defaultDailyReminderHour,
            dailyReminderMinute: defaults.object(forKey: NotificationSettings.dailyReminderMinuteKey) as? Int
                ?? NotificationSettings.defaultDailyReminderMinute,
            calendar: calendar
        )

        NotificationManager().apply(plan)
    }
}
