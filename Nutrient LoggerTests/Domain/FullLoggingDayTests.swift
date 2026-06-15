//
//  FullLoggingDayTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/14/26.
//

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
