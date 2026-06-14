//
//  LoggingStreak.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

struct LoggingStreak: Equatable {

    var count: Int = 0
    var lastLoggedDate: SimpleDate? = nil

    static let empty = LoggingStreak()

    /// Returns the streak updated for `today`, given whether at least one food was logged on `today`.
    ///
    /// A streak continues if food was logged yesterday and today. It stays alive (but unchanged)
    /// if nothing has been logged yet today but the streak was active as of yesterday - it only
    /// breaks once a full day passes with nothing logged.
    func updated(loggedToday: Bool, today: SimpleDate = .today) -> LoggingStreak {
        if loggedToday {
            if lastLoggedDate == today {
                return self
            } else if lastLoggedDate == today.adding(days: -1) {
                return LoggingStreak(count: count + 1, lastLoggedDate: today)
            } else {
                return LoggingStreak(count: 1, lastLoggedDate: today)
            }
        } else {
            guard let lastLoggedDate, lastLoggedDate.daysTo(today) < 2 else {
                return .empty
            }
            return self
        }
    }
}
