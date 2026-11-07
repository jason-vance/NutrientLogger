//
//  NotificationCoordinator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation
import SwiftData
import SwinjectAutoregistration

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
            streakWarningEnabled: defaults.object(forKey: NotificationSettings.streakWarningEnabledKey) as? Bool
                ?? NotificationSettings.defaultStreakWarningEnabled,
            calendar: calendar
        )

        let gapTipEnabled = defaults.object(forKey: NotificationSettings.gapTipEnabledKey) as? Bool
            ?? NotificationSettings.defaultGapTipEnabled
        let gapTip = GapTip.fireDate(
            now: now,
            isFullLoggingDay: FullLoggingDay.isComplete(todaysFoods, on: today),
            enabled: gapTipEnabled,
            calendar: calendar
        ).flatMap { fireDate in
            gapTipBody(for: todaysFoods, on: today).map { (fireDate: fireDate, body: $0) }
        }

        NotificationManager().apply(plan, gapTip: gapTip)
    }

    // Reading the day's foods hits the database, and reschedule runs on every backgrounding, so the
    // tip is only recomputed when the day's foods change.
    private static var cachedGapTip: (key: String, body: String?)?

    private static func gapTipBody(for foods: [ConsumedFood], on date: SimpleDate) -> String? {
        let key = "\(date)-" + foods.map { "\($0.fdcId):\($0.portionAmount)" }.sorted().joined(separator: ",")
        if let cachedGapTip, cachedGapTip.key == key { return cachedGapTip.body }

        let userService: UserService = swinjectContainer~>UserService.self
        let watch = DashboardWeeklyNutrientWatchSection.computeWeeklyWatch(
            foods: foods,
            ratios: [],
            user: userService.currentUser.withReferenceAgeIfMissing,
            rdiLibrary: swinjectContainer~>NutrientRdiLibrary.self,
            remoteDatabase: swinjectContainer~>RemoteDatabase.self
        )
        let body = GapTip.body(
            lowNames: watch.deficiencies.map(\.name),
            foods: watch.deficiencies.first.flatMap { GapFoods.sentence($0.suggestions) }
        )
        cachedGapTip = (key, body)
        return body
    }
}
