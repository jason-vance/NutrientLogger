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
            firstDay: firstDayProgress(todaysFoods: todaysFoods, today: today, now: now, calendar: calendar, modelContext: modelContext),
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

    /// Where a new user stands on the way to their first full day, or nil once the first-day
    /// reminder no longer applies. Earlier days are only read inside the first week after
    /// onboarding, when there are few of them.
    private static func firstDayProgress(
        todaysFoods: [ConsumedFood],
        today: SimpleDate,
        now: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) -> NotificationPlanner.FirstDayProgress? {
        let defaults = UserDefaults.standard
        let hasHadFullDay = defaults.bool(forKey: FirstFullDayTiming.loggedKey)
            || FullLoggingDay.isComplete(todaysFoods, on: today)
        guard FirstDayReminder.applies(
            onboardingStartedAt: defaults.double(forKey: "onboardingStartedAt"),
            hasHadFullDay: hasHadFullDay,
            now: now,
            calendar: calendar
        ) else { return nil }

        let earlierFoods = (try? modelContext.fetch(FetchDescriptor<ConsumedFood>(
            predicate: #Predicate { $0.dateLogged < today }
        ))) ?? []
        guard !FullLoggingDay.hasEarlierFullDay(earlierFoods, before: today) else { return nil }

        let userService: UserService = swinjectContainer~>UserService.self
        return .init(
            mealTimesLoggedToday: Set(todaysFoods.map(\.mealTime)),
            hasLoggedBefore: !earlierFoods.isEmpty,
            diet: userService.currentUser.dietPreset
        )
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
