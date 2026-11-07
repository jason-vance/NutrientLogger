//
//  SearchSessionLogTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/4/26.
//

import Testing

struct SearchSessionLogTests {

    private struct Logged {
        let name: String
        let date: SimpleDate
        let mealTime: MealTime
    }

    private let today = SimpleDate(year: 2026, month: 11, day: 4)!
    private var yesterday: SimpleDate { today.adding(days: -1) }

    @Test func summarizesTheNewestNames() {
        #expect(SearchSessionLog.namesSummary(newestFirst: ["Coffee", "Toast"]) == "Coffee, Toast")
        #expect(SearchSessionLog.namesSummary(newestFirst: ["Coffee", "Toast", "Eggs", "Banana", "Rice"]) == "Coffee, Toast, Eggs +2")
        #expect(SearchSessionLog.namesSummary(newestFirst: []) == "")
    }

    @Test func groupsByDayAndMealInEatingOrder() {
        let items = [
            Logged(name: "Steak", date: today, mealTime: .dinner),
            Logged(name: "Eggs", date: today, mealTime: .breakfast),
            Logged(name: "Rice", date: yesterday, mealTime: .lunch),
            Logged(name: "Toast", date: today, mealTime: .breakfast),
        ]
        let groups = SearchSessionLog.groups(items, date: \.date, mealTime: \.mealTime)

        #expect(groups.map(\.mealTime) == [.lunch, .breakfast, .dinner])
        #expect(groups.map(\.date) == [yesterday, today, today])
        #expect(groups[1].items.map(\.name) == ["Eggs", "Toast"])
    }

    @Test func namesOtherDaysInTheTitle() {
        #expect(SearchSessionLog.title(date: today, mealTime: .lunch, today: today, dayName: "Today") == "Lunch")
        #expect(SearchSessionLog.title(date: yesterday, mealTime: .lunch, today: today, dayName: "Yesterday") == "Lunch · Yesterday")
    }

    @Test func suggestsAMealNameFromTheFoods() {
        #expect(SearchSessionLog.suggestedMealName(for: ["Egg, whole, fried", "Bacon, cooked", "Coffee, brewed"])
            == "Egg, Bacon & Coffee")
        #expect(SearchSessionLog.suggestedMealName(for: ["Steak", "Egg, whole", "Egg, yolk only"]) == "Steak & Egg")
        #expect(SearchSessionLog.suggestedMealName(for: ["Oatmeal, made with water"]) == "Oatmeal")
        #expect(SearchSessionLog.suggestedMealName(for: ["A", "B", "C", "D"]) == "A, B & C")
        #expect(SearchSessionLog.suggestedMealName(for: []) == "My Meal")
    }
}
