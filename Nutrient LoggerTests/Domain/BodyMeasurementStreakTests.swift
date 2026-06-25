import Testing

struct BodyMeasurementStreakTests {

    let today = SimpleDate(rawValue: 20260625)!
    let threeDaysAgo = SimpleDate(rawValue: 20260622)!
    let sevenDaysAgo = SimpleDate(rawValue: 20260618)!
    let tenDaysAgo = SimpleDate(rawValue: 20260615)!
    let fourteenDaysAgo = SimpleDate(rawValue: 20260611)!
    let twentyDaysAgo = SimpleDate(rawValue: 20260605)!

    // MARK: - Logging

    @Test func startsStreakOnFirstEverMeasurement() {
        let streak = BodyMeasurementStreak.empty
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 1)
        #expect(streak.weekStartDate == today)
    }

    @Test func doesNotIncrementWithinSameWeekWindow() {
        let streak = BodyMeasurementStreak(count: 2, weekStartDate: threeDaysAgo)
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 2)
        #expect(streak.weekStartDate == threeDaysAgo)
    }

    @Test func incrementsWhenNewWeekStarts() {
        let streak = BodyMeasurementStreak(count: 2, weekStartDate: sevenDaysAgo)
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 3)
        #expect(streak.weekStartDate == today)
    }

    @Test func incrementsAtThirteenDayGap() {
        let streak = BodyMeasurementStreak(count: 1, weekStartDate: tenDaysAgo)
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 2)
        #expect(streak.weekStartDate == today)
    }

    @Test func restartsAfterFourteenDayGap() {
        let streak = BodyMeasurementStreak(count: 5, weekStartDate: fourteenDaysAgo)
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 1)
        #expect(streak.weekStartDate == today)
    }

    @Test func restartsAfterLongGap() {
        let streak = BodyMeasurementStreak(count: 10, weekStartDate: twentyDaysAgo)
            .updated(loggedInPastWeek: true, today: today)

        #expect(streak.count == 1)
        #expect(streak.weekStartDate == today)
    }

    // MARK: - Grace period

    @Test func streakStaysAliveWithinGracePeriod() {
        let streak = BodyMeasurementStreak(count: 3, weekStartDate: tenDaysAgo)
            .updated(loggedInPastWeek: false, today: today)

        #expect(streak.count == 3)
        #expect(streak.weekStartDate == tenDaysAgo)
    }

    @Test func streakBreaksAfterGracePeriodExpires() {
        let streak = BodyMeasurementStreak(count: 3, weekStartDate: fourteenDaysAgo)
            .updated(loggedInPastWeek: false, today: today)

        #expect(streak == .empty)
    }

    @Test func emptyStreakStaysEmptyWithNoMeasurements() {
        let streak = BodyMeasurementStreak.empty
            .updated(loggedInPastWeek: false, today: today)

        #expect(streak == .empty)
    }

    // MARK: - Reconciliation

    @Test func reconciledPrefersRemoteWhenLocalIsEmpty() {
        let remote = BodyMeasurementStreak(count: 3, weekStartDate: threeDaysAgo)

        let reconciled = BodyMeasurementStreak.reconciled(local: .empty, remote: remote)

        #expect(reconciled == remote)
    }

    @Test func reconciledPrefersLocalWhenRemoteIsEmpty() {
        let local = BodyMeasurementStreak(count: 3, weekStartDate: threeDaysAgo)

        let reconciled = BodyMeasurementStreak.reconciled(local: local, remote: .empty)

        #expect(reconciled == local)
    }

    @Test func reconciledStaysEmptyWhenBothAreEmpty() {
        let reconciled = BodyMeasurementStreak.reconciled(local: .empty, remote: .empty)

        #expect(reconciled == .empty)
    }

    @Test func reconciledPrefersMoreRecentWeekStartDate() {
        let older = BodyMeasurementStreak(count: 5, weekStartDate: tenDaysAgo)
        let newer = BodyMeasurementStreak(count: 2, weekStartDate: threeDaysAgo)

        #expect(BodyMeasurementStreak.reconciled(local: older, remote: newer) == newer)
        #expect(BodyMeasurementStreak.reconciled(local: newer, remote: older) == newer)
    }

    @Test func reconciledPrefersHigherCountWhenDatesMatch() {
        let lower = BodyMeasurementStreak(count: 2, weekStartDate: threeDaysAgo)
        let higher = BodyMeasurementStreak(count: 5, weekStartDate: threeDaysAgo)

        #expect(BodyMeasurementStreak.reconciled(local: lower, remote: higher) == higher)
        #expect(BodyMeasurementStreak.reconciled(local: higher, remote: lower) == higher)
    }
}
