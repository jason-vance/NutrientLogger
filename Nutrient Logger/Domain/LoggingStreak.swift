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

    /// Reconciles a locally-stored streak with the copy persisted in iCloud.
    ///
    /// This handles the case where the app was reinstalled and local storage was wiped, but
    /// iCloud retains the previous streak. The streak with the more recently logged date wins,
    /// since it reflects the most up-to-date activity; ties prefer the higher count.
    static func reconciled(local: LoggingStreak, remote: LoggingStreak) -> LoggingStreak {
        guard let localDate = local.lastLoggedDate else { return remote }
        guard let remoteDate = remote.lastLoggedDate else { return local }

        if localDate == remoteDate {
            return local.count >= remote.count ? local : remote
        }

        return localDate > remoteDate ? local : remote
    }
}
