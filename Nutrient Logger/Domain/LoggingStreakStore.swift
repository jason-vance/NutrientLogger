//
//  LoggingStreakStore.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

/// Persists the logging streak locally (for fast access and `@AppStorage` reactivity) and to
/// iCloud's key-value store, so the streak survives an app reinstall.
///
/// If the iCloud key-value storage entitlement isn't configured, `NSUbiquitousKeyValueStore`
/// calls are harmless no-ops, so the streak still works using local storage alone.
struct LoggingStreakStore {

    static let countKey = "loggingStreakCount"
    static let lastLoggedDateKey = "loggingStreakLastLoggedDate"

    private let local: UserDefaults
    private let remote: NSUbiquitousKeyValueStore

    init(local: UserDefaults = .standard, remote: NSUbiquitousKeyValueStore = .default) {
        self.local = local
        self.remote = remote
    }

    /// Loads the streak, reconciling local storage with iCloud in case this is a fresh install.
    func load() -> LoggingStreak {
        let localStreak = LoggingStreak(
            count: local.integer(forKey: Self.countKey),
            lastLoggedDate: SimpleDate(rawValue: UInt32(local.integer(forKey: Self.lastLoggedDateKey)))
        )
        let remoteStreak = LoggingStreak(
            count: Int(remote.longLong(forKey: Self.countKey)),
            lastLoggedDate: SimpleDate(rawValue: UInt32(remote.longLong(forKey: Self.lastLoggedDateKey)))
        )

        return LoggingStreak.reconciled(local: localStreak, remote: remoteStreak)
    }

    /// Saves the streak to both local storage and iCloud.
    func save(_ streak: LoggingStreak) {
        let lastLoggedDateRaw = streak.lastLoggedDate.map { Int($0) } ?? 0

        local.set(streak.count, forKey: Self.countKey)
        local.set(lastLoggedDateRaw, forKey: Self.lastLoggedDateKey)

        remote.set(Int64(streak.count), forKey: Self.countKey)
        remote.set(Int64(lastLoggedDateRaw), forKey: Self.lastLoggedDateKey)
        remote.synchronize()
    }
}
