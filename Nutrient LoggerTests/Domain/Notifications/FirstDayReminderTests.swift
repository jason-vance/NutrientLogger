//
//  FirstDayReminderTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/11/26.
//

import Testing
import Foundation

struct FirstDayReminderTests {

    // Onboarding started Wednesday 2026-11-11 at 8 am.
    let onboardingStartedAt = Date.from(year: 2026, month: 11, day: 11, hr: 8, min: 0).timeIntervalSince1970
    let sameDay = Date.from(year: 2026, month: 11, day: 11, hr: 19, min: 0)
    let day7 = Date.from(year: 2026, month: 11, day: 17, hr: 19, min: 0)
    let day8 = Date.from(year: 2026, month: 11, day: 18, hr: 19, min: 0)

    // MARK: - Who it applies to

    @Test func appliesToANewUserWithoutAFullDay() {
        #expect(FirstDayReminder.applies(onboardingStartedAt: onboardingStartedAt, hasHadFullDay: false, now: sameDay))
        #expect(FirstDayReminder.applies(onboardingStartedAt: onboardingStartedAt, hasHadFullDay: false, now: day7))
    }

    @Test func stopsAfterTheFirstWeek() {
        #expect(!FirstDayReminder.applies(onboardingStartedAt: onboardingStartedAt, hasHadFullDay: false, now: day8))
    }

    @Test func stopsOnceThereIsAFullDay() {
        #expect(!FirstDayReminder.applies(onboardingStartedAt: onboardingStartedAt, hasHadFullDay: true, now: sameDay))
    }

    @Test func skipsUsersFromBeforeOnboardingWasTimed() {
        #expect(!FirstDayReminder.applies(onboardingStartedAt: 0, hasHadFullDay: false, now: sameDay))
    }

    // MARK: - Wording

    @Test func neverLoggedAsksForAFirstMeal() {
        let message = FirstDayReminder.message(mealTimesLogged: [], hasLoggedBefore: false, diet: .carnivore)
        #expect(message.title == "What did you eat today?")
        #expect(message.body == "Log a meal to see its vitamins and minerals, not just its calories.")
    }

    @Test func loggedOnAnEarlierDayButNotTodayAsksForAFullDay() {
        let message = FirstDayReminder.message(mealTimesLogged: [], hasLoggedBefore: true, diet: .carnivore)
        #expect(message.title == "One full day shows your gaps")
        #expect(message.body == "Log breakfast, lunch and dinner today to see which vitamins and minerals your carnivore day is short on.")
    }

    @Test func oneMealMissingNamesIt() {
        let message = FirstDayReminder.message(mealTimesLogged: [.breakfast, .lunch], hasLoggedBefore: false, diet: .ketoLowCarb)
        #expect(message.title == "One meal to go")
        #expect(message.body == "Log dinner to see which vitamins and minerals your keto day is short on.")
    }

    @Test func twoMealsMissingNamesBoth() {
        let message = FirstDayReminder.message(mealTimesLogged: [.breakfast], hasLoggedBefore: false, diet: .balanced)
        #expect(message.title == "Finish today to see your gaps")
        #expect(message.body == "Log lunch and dinner to see which vitamins and minerals your day is short on.")
    }

    @Test func snacksDontCountAsMeals() {
        let message = FirstDayReminder.message(mealTimesLogged: [.afternoonSnack], hasLoggedBefore: false, diet: .paleo)
        #expect(message.title == "Finish today to see your gaps")
        #expect(message.body == "Log breakfast, lunch and dinner to see which vitamins and minerals your paleo day is short on.")
    }

    @Test func noDietLeavesTheDayUnlabeled() {
        let message = FirstDayReminder.message(mealTimesLogged: [.breakfast, .dinner], hasLoggedBefore: true, diet: nil)
        #expect(message.body == "Log lunch to see which vitamins and minerals your day is short on.")
    }

    @Test func everyDietReadsBeforeDay() {
        #expect(FirstDayReminder.dayName(.plantBased) == "plant-based")
        #expect(FirstDayReminder.dayName(.pescatarian) == "pescatarian")
        #expect(FirstDayReminder.dayName(.balanced) == nil)
    }
}
