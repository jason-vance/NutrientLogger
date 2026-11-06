//
//  ReviewRequestTrigger.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// When to show Apple's rating prompt: after a week of logging, on a day the user has logged
/// breakfast, lunch and dinner. By then they've had the app's payoff more than once, so the
/// rating reflects real use rather than a first impression.
enum ReviewRequestTrigger {

    static let lastRequestedDateKey = "lastReviewRequestDate"
    /// Set by the old "Are you enjoying the app?" flow once the user reviewed, sent feedback or
    /// chose "Don't ask again". Any of those means don't ask them automatically again.
    static let optedOutKey = "stopPromptingForReviews"

    static let minimumStreakDays = 7
    /// Apple shows the prompt at most 3 times a year, so asking more often only wastes them.
    static let minimumDaysBetweenRequests = 120

    static func shouldRequest(
        streakCount: Int,
        isFullLoggingDay: Bool,
        lastRequestedDate: SimpleDate?,
        hasOptedOut: Bool,
        today: SimpleDate = .today
    ) -> Bool {
        guard !hasOptedOut, isFullLoggingDay, streakCount >= minimumStreakDays else { return false }
        guard let lastRequestedDate else { return true }
        return lastRequestedDate.daysTo(today) >= minimumDaysBetweenRequests
    }
}
