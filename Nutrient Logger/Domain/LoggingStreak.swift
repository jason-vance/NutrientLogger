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
    var longestCount: Int = 0

    static let empty = LoggingStreak()

    /// Returns the streak updated for `today`, given whether at least one food was logged on `today`.
    ///
    /// A streak continues if food was logged yesterday and today. It stays alive (but unchanged)
    /// if nothing has been logged yet today but the streak was active as of yesterday - it only
    /// breaks once a full day passes with nothing logged. `longestCount` tracks the highest streak
    /// ever reached and is never decreased.
    func updated(loggedToday: Bool, today: SimpleDate = .today) -> LoggingStreak {
        if loggedToday {
            if lastLoggedDate == today {
                return self
            } else if lastLoggedDate == today.adding(days: -1) {
                let newCount = count + 1
                return LoggingStreak(count: newCount, lastLoggedDate: today, longestCount: max(longestCount, newCount))
            } else {
                return LoggingStreak(count: 1, lastLoggedDate: today, longestCount: max(longestCount, 1))
            }
        } else {
            guard let lastLoggedDate, lastLoggedDate.daysTo(today) < 2 else {
                return LoggingStreak(count: 0, lastLoggedDate: nil, longestCount: longestCount)
            }
            return self
        }
    }

    /// Reconciles a locally-stored streak with the copy persisted in iCloud.
    ///
    /// This handles the case where the app was reinstalled and local storage was wiped, but
    /// iCloud retains the previous streak. The streak with the more recently logged date wins,
    /// since it reflects the most up-to-date activity; ties prefer the higher count. The longest
    /// streak ever achieved is kept regardless of which side wins, since it's a high-water mark.
    static func reconciled(local: LoggingStreak, remote: LoggingStreak) -> LoggingStreak {
        let longest = max(local.longestCount, remote.longestCount)

        var winner: LoggingStreak
        if let localDate = local.lastLoggedDate, let remoteDate = remote.lastLoggedDate {
            if localDate == remoteDate {
                winner = local.count >= remote.count ? local : remote
            } else {
                winner = localDate > remoteDate ? local : remote
            }
        } else if local.lastLoggedDate != nil {
            winner = local
        } else {
            winner = remote
        }

        winner.longestCount = longest
        return winner
    }
}
