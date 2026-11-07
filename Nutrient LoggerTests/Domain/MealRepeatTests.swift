//
//  MealRepeatTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct MealRepeatTests {

    private let friday = SimpleDate(year: 2026, month: 11, day: 6)!

    private func food(_ name: String, _ date: SimpleDate, _ mealTime: MealTime = .breakfast) -> ConsumedFood {
        ConsumedFood(fdcId: name.count, name: name, portionAmount: 2, portionGramWeight: 50, portionName: "large",
                     dateLogged: date, mealTime: mealTime)
    }

    @Test func findsTheMostRecentDayWithThatMeal() {
        let foods = [
            food("Eggs", friday.adding(days: -3)),
            food("Bacon", friday.adding(days: -1)),
            food("Coffee", friday.adding(days: -1)),
            food("Steak", friday.adding(days: -1), .dinner),
        ]
        let previous = MealRepeat.previous(.breakfast, before: friday, in: foods)
        #expect(previous?.date == friday.adding(days: -1))
        #expect(previous?.foods.map(\.name).sorted() == ["Bacon", "Coffee"])
        #expect(previous?.daysBack == 1)
    }

    @Test func looksBackOnlyOneWeek() {
        #expect(MealRepeat.previous(.breakfast, before: friday, in: [food("Eggs", friday.adding(days: -8))]) == nil)
        #expect(MealRepeat.previous(.breakfast, before: friday, in: [food("Eggs", friday.adding(days: -7))])?.daysBack == 7)
    }

    @Test func ignoresTheSameDayAndLater() {
        let foods = [food("Eggs", friday), food("Toast", friday.adding(days: 1))]
        #expect(MealRepeat.previous(.breakfast, before: friday, in: foods) == nil)
    }

    @Test func labelsReadNaturally() {
        let yesterday = MealRepeat.Previous(date: friday.adding(days: -1), foods: [], daysBack: 1)
        #expect(MealRepeat.label(for: yesterday, mealTime: .breakfast, selectedDate: friday, today: friday)
            == "Repeat yesterday's breakfast")

        let tuesday = MealRepeat.Previous(date: friday.adding(days: -3), foods: [], daysBack: 3)
        #expect(MealRepeat.label(for: tuesday, mealTime: .morningSnack, selectedDate: friday, today: friday)
            == "Repeat Tuesday's morning snack")

        let lastWeek = MealRepeat.Previous(date: friday.adding(days: -7), foods: [], daysBack: 7)
        #expect(MealRepeat.label(for: lastWeek, mealTime: .dinner, selectedDate: friday, today: friday)
            == "Repeat last Friday's dinner")
    }

    @Test func copiesKeepThePortionsOnTheNewDay() {
        let copies = MealRepeat.copies(of: [food("Eggs", friday.adding(days: -1))], to: friday)
        #expect(copies.count == 1)
        #expect(copies[0].dateLogged == friday)
        #expect(copies[0].portionAmount == 2)
        #expect(copies[0].portionName == "large")
        #expect(copies[0].mealTime == .breakfast)
    }
}
