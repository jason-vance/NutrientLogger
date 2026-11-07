//
//  FullLoggingDay.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

enum FullLoggingDay {

    /// The meal times that must each have at least one logged food for a day to count as "full."
    static let requiredMealTimes: [MealTime] = [.breakfast, .lunch, .dinner]

    /// Returns whether `foods` includes at least one entry for `date` in each of `requiredMealTimes`.
    static func isComplete(_ foods: [ConsumedFood], on date: SimpleDate) -> Bool {
        let loggedMealTimes = Set(
            foods
                .filter { $0.dateLogged == date }
                .map { $0.mealTime }
        )

        return requiredMealTimes.allSatisfy { loggedMealTimes.contains($0) }
    }

    /// Whether any day before `date` was already full. Used to tell a user's very first full day
    /// from later ones, including for people who logged full days before this was measured.
    static func hasEarlierFullDay(_ foods: [ConsumedFood], before date: SimpleDate) -> Bool {
        let mealTimesByDate = Dictionary(grouping: foods.filter { $0.dateLogged < date }, by: \.dateLogged)
            .mapValues { Set($0.map(\.mealTime)) }
        return mealTimesByDate.values.contains { mealTimes in
            requiredMealTimes.allSatisfy { mealTimes.contains($0) }
        }
    }
}

/// How long a new user took to log their first full day, measured from when onboarding started.
/// Step one of the first-session plan: if this is days, not minutes, logging is too slow.
enum FirstFullDayTiming {

    static let loggedKey = "firstFullDayLogged"

    /// Whole minutes since onboarding started. Nil when the start wasn't recorded.
    static func minutes(onboardingStartedAt: Double, now: Date) -> Int? {
        guard onboardingStartedAt > 0 else { return nil }
        return max(0, Int((now.timeIntervalSince1970 - onboardingStartedAt) / 60))
    }

    /// 1 for the same calendar day onboarding started, 2 for the next day, and so on.
    static func dayNumber(onboardingStartedAt: Double, now: Date, calendar: Calendar = .current) -> Int? {
        guard onboardingStartedAt > 0 else { return nil }
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: onboardingStartedAt))
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        return max(1, days + 1)
    }
}
