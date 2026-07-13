import Foundation

struct BodyMeasurementStreakStore {

    static let countKey = "bodyMeasurementStreakCount"
    static let weekStartDateKey = "bodyMeasurementStreakWeekStartDate"

    private let local: UserDefaults
    private let remote: NSUbiquitousKeyValueStore

    init(local: UserDefaults = .standard, remote: NSUbiquitousKeyValueStore = .default) {
        self.local = local
        self.remote = remote
    }

    func load() -> BodyMeasurementStreak {
        let localStreak = BodyMeasurementStreak(
            count: local.integer(forKey: Self.countKey),
            weekStartDate: SimpleDate(rawValue: UInt32(local.integer(forKey: Self.weekStartDateKey)))
        )
        let remoteStreak = BodyMeasurementStreak(
            count: Int(remote.longLong(forKey: Self.countKey)),
            weekStartDate: SimpleDate(rawValue: UInt32(remote.longLong(forKey: Self.weekStartDateKey)))
        )

        return BodyMeasurementStreak.reconciled(local: localStreak, remote: remoteStreak)
    }

    func save(_ streak: BodyMeasurementStreak) {
        let weekStartDateRaw = streak.weekStartDate.map { Int($0) } ?? 0

        local.set(streak.count, forKey: Self.countKey)
        local.set(weekStartDateRaw, forKey: Self.weekStartDateKey)

        remote.set(Int64(streak.count), forKey: Self.countKey)
        remote.set(Int64(weekStartDateRaw), forKey: Self.weekStartDateKey)
        remote.synchronize()
    }

    /// Debug-only: clears the streak from both local storage and iCloud. Clearing local storage
    /// alone isn't enough to simulate a fresh install — `load()`'s reconciliation would just pull
    /// the old streak back down from iCloud.
    func reset() {
        local.removeObject(forKey: Self.countKey)
        local.removeObject(forKey: Self.weekStartDateKey)

        remote.removeObject(forKey: Self.countKey)
        remote.removeObject(forKey: Self.weekStartDateKey)
        remote.synchronize()
    }
}
