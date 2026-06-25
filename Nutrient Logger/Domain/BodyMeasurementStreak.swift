import Foundation

struct BodyMeasurementStreak: Equatable {

    var count: Int = 0
    var weekStartDate: SimpleDate? = nil

    static let empty = BodyMeasurementStreak()

    func updated(loggedInPastWeek: Bool, today: SimpleDate = .today) -> BodyMeasurementStreak {
        if loggedInPastWeek {
            guard let weekStartDate else {
                return BodyMeasurementStreak(count: 1, weekStartDate: today)
            }
            let days = weekStartDate.daysTo(today)
            if days < 7 {
                return self
            } else if days < 14 {
                return BodyMeasurementStreak(count: count + 1, weekStartDate: today)
            } else {
                return BodyMeasurementStreak(count: 1, weekStartDate: today)
            }
        } else {
            guard let weekStartDate, weekStartDate.daysTo(today) < 14 else {
                return .empty
            }
            return self
        }
    }

    static func reconciled(local: BodyMeasurementStreak, remote: BodyMeasurementStreak) -> BodyMeasurementStreak {
        guard let localDate = local.weekStartDate else { return remote }
        guard let remoteDate = remote.weekStartDate else { return local }

        if localDate == remoteDate {
            return local.count >= remote.count ? local : remote
        }

        return localDate > remoteDate ? local : remote
    }
}
