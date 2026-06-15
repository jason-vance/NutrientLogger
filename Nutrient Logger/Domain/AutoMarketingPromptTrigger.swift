//
//  AutoMarketingPromptTrigger.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

enum AutoMarketingPromptTrigger {

    /// After the prompt is shown (whether purchased or dismissed), it won't auto-show again
    /// until this many days have passed.
    static let minimumDaysBetweenPrompts = 30

    /// Returns whether the marketing paywall should be automatically shown.
    ///
    /// Fires the first time the user completes a "full" logging day (see `FullLoggingDay`),
    /// then at most once every `minimumDaysBetweenPrompts` days after that.
    static func shouldShow(
        isFullLoggingDay: Bool,
        isSubscribed: Bool,
        lastShownDate: SimpleDate?,
        today: SimpleDate = .today
    ) -> Bool {
        guard isFullLoggingDay, !isSubscribed else { return false }
        guard let lastShownDate else { return true }
        return lastShownDate.daysTo(today) >= minimumDaysBetweenPrompts
    }
}
