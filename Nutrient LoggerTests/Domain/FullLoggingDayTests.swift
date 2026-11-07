//
//  FullLoggingDayTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation
import Testing

struct FullLoggingDayTests {

    let today = SimpleDate(rawValue: 20260614)!
    let yesterday = SimpleDate(rawValue: 20260613)!

    private func food(mealTime: MealTime, dateLogged: SimpleDate) -> ConsumedFood {
        ConsumedFood(
            fdcId: 1,
            name: "Test Food",
            portionAmount: 1,
            portionGramWeight: 100,
            portionName: "serving",
            dateLogged: dateLogged,
            mealTime: mealTime
        )
    }

    @Test func testIsCompleteWhenBreakfastLunchAndDinnerAreAllLogged() throws {
        let foods = [
            food(mealTime: .breakfast, dateLogged: today),
            food(mealTime: .lunch, dateLogged: today),
            food(mealTime: .dinner, dateLogged: today),
        ]

        #expect(FullLoggingDay.isComplete(foods, on: today))
    }

    @Test func testIsNotCompleteWhenAMealTimeIsMissing() throws {
        let foods = [
            food(mealTime: .breakfast, dateLogged: today),
            food(mealTime: .lunch, dateLogged: today),
        ]

        #expect(!FullLoggingDay.isComplete(foods, on: today))
    }

    @Test func testSnacksDoNotCountTowardCompletion() throws {
        let foods = [
            food(mealTime: .breakfast, dateLogged: today),
            food(mealTime: .lunch, dateLogged: today),
            food(mealTime: .morningSnack, dateLogged: today),
            food(mealTime: .afternoonSnack, dateLogged: today),
            food(mealTime: .eveningSnack, dateLogged: today),
        ]

        #expect(!FullLoggingDay.isComplete(foods, on: today))
    }

    @Test func testOnlyCountsFoodsLoggedOnTheGivenDate() throws {
        let foods = [
            food(mealTime: .breakfast, dateLogged: today),
            food(mealTime: .lunch, dateLogged: today),
            food(mealTime: .dinner, dateLogged: yesterday),
        ]

        #expect(!FullLoggingDay.isComplete(foods, on: today))
    }

    @Test func testEmptyFoodsIsNotComplete() throws {
        #expect(!FullLoggingDay.isComplete([], on: today))
    }
}

struct FirstFullDayTests {

    private let friday = SimpleDate(year: 2026, month: 11, day: 6)!

    private func food(_ date: SimpleDate, _ mealTime: MealTime) -> ConsumedFood {
        ConsumedFood(fdcId: 1, name: "Eggs", portionAmount: 1, portionGramWeight: 50, portionName: "large",
                     dateLogged: date, mealTime: mealTime)
    }

    @Test func findsAnEarlierFullDay() {
        let thursday = friday.adding(days: -1)
        let full = [food(thursday, .breakfast), food(thursday, .lunch), food(thursday, .dinner)]
        #expect(FullLoggingDay.hasEarlierFullDay(full, before: friday))
        #expect(!FullLoggingDay.hasEarlierFullDay(full, before: thursday))
        #expect(!FullLoggingDay.hasEarlierFullDay(Array(full.prefix(2)), before: friday))
    }

    @Test func timesFromOnboardingStart() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 8))!
        let sameEvening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 20, minute: 30))!
        let nextDay = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 9))!

        #expect(FirstFullDayTiming.minutes(onboardingStartedAt: start.timeIntervalSince1970, now: sameEvening) == 750)
        #expect(FirstFullDayTiming.dayNumber(onboardingStartedAt: start.timeIntervalSince1970, now: sameEvening, calendar: calendar) == 1)
        #expect(FirstFullDayTiming.dayNumber(onboardingStartedAt: start.timeIntervalSince1970, now: nextDay, calendar: calendar) == 2)
        #expect(FirstFullDayTiming.minutes(onboardingStartedAt: 0, now: nextDay) == nil)
    }
}
