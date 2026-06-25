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
}
