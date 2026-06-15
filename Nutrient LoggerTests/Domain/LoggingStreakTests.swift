//
//  LoggingStreakTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/14/26.
//

import Testing

struct LoggingStreakTests {

    let today = SimpleDate(rawValue: 20260614)!
    let yesterday = SimpleDate(rawValue: 20260613)!
    let twoDaysAgo = SimpleDate(rawValue: 20260612)!

    @Test func testStartsStreakOnFirstEverLog() throws {
        let streak = LoggingStreak.empty.updated(loggedToday: true, today: today)

        #expect(streak.count == 1)
        #expect(streak.lastLoggedDate == today)
    }

    @Test func testContinuesStreakWhenLoggedYesterdayAndToday() throws {
        let streak = LoggingStreak(count: 5, lastLoggedDate: yesterday)
            .updated(loggedToday: true, today: today)

        #expect(streak.count == 6)
        #expect(streak.lastLoggedDate == today)
    }

    @Test func testDoesNotDoubleCountWhenAlreadyCreditedToday() throws {
        let streak = LoggingStreak(count: 5, lastLoggedDate: today)
            .updated(loggedToday: true, today: today)

        #expect(streak.count == 5)
        #expect(streak.lastLoggedDate == today)
    }

    @Test func testRestartsStreakAfterAGapInLogging() throws {
        let streak = LoggingStreak(count: 5, lastLoggedDate: twoDaysAgo)
            .updated(loggedToday: true, today: today)

        #expect(streak.count == 1)
        #expect(streak.lastLoggedDate == today)
    }

    @Test func testStreakStaysAliveWhenYesterdayWasLoggedButTodayIsNotYet() throws {
        let streak = LoggingStreak(count: 5, lastLoggedDate: yesterday)
            .updated(loggedToday: false, today: today)

        #expect(streak.count == 5)
        #expect(streak.lastLoggedDate == yesterday)
    }

    @Test func testStreakResetsAfterAFullDayWithNothingLogged() throws {
        let streak = LoggingStreak(count: 5, lastLoggedDate: twoDaysAgo)
            .updated(loggedToday: false, today: today)

        #expect(streak.count == 0)
        #expect(streak.lastLoggedDate == nil)
    }

    @Test func testEmptyStreakStaysEmptyWithNothingLoggedYet() throws {
        let streak = LoggingStreak.empty.updated(loggedToday: false, today: today)

        #expect(streak.count == 0)
        #expect(streak.lastLoggedDate == nil)
    }

    @Test func testReconciledPrefersRemoteWhenLocalIsEmpty() throws {
        let remote = LoggingStreak(count: 5, lastLoggedDate: yesterday)

        let reconciled = LoggingStreak.reconciled(local: .empty, remote: remote)

        #expect(reconciled == remote)
    }

    @Test func testReconciledPrefersLocalWhenRemoteIsEmpty() throws {
        let local = LoggingStreak(count: 5, lastLoggedDate: yesterday)

        let reconciled = LoggingStreak.reconciled(local: local, remote: .empty)

        #expect(reconciled == local)
    }

    @Test func testReconciledStaysEmptyWhenBothAreEmpty() throws {
        let reconciled = LoggingStreak.reconciled(local: .empty, remote: .empty)

        #expect(reconciled == .empty)
    }

    @Test func testReconciledPrefersTheMoreRecentlyLoggedStreak() throws {
        let local = LoggingStreak(count: 2, lastLoggedDate: twoDaysAgo)
        let remote = LoggingStreak(count: 9, lastLoggedDate: yesterday)

        #expect(LoggingStreak.reconciled(local: local, remote: remote) == remote)
        #expect(LoggingStreak.reconciled(local: remote, remote: local) == remote)
    }

    @Test func testReconciledPrefersTheHigherCountWhenLastLoggedDatesMatch() throws {
        let lowerCount = LoggingStreak(count: 3, lastLoggedDate: today)
        let higherCount = LoggingStreak(count: 7, lastLoggedDate: today)

        #expect(LoggingStreak.reconciled(local: lowerCount, remote: higherCount) == higherCount)
        #expect(LoggingStreak.reconciled(local: higherCount, remote: lowerCount) == higherCount)
    }
}
