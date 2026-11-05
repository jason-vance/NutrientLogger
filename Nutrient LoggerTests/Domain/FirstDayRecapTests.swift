//
//  FirstDayRecapTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/4/26.
//

import Testing

struct FirstDayRecapTests {

    private func gap(_ name: String, _ percent: Double) -> FirstDayRecap.Gap {
        FirstDayRecap.Gap(id: name, name: name, percentOfGoal: percent)
    }

    @Test func headlineNamesTheBiggestGapsLowestFirst() {
        let recap = FirstDayRecap(
            lows: [gap("Potassium", 0.41), gap("Magnesium", 0.30)],
            highCount: 0,
            balanceCount: 0
        )
        #expect(recap.headline == "You're low on magnesium and potassium today")
    }

    @Test func showsAtMostThreeGaps() {
        let recap = FirstDayRecap(
            lows: [gap("Vitamin D", 0.05), gap("Vitamin E", 0.2), gap("Magnesium", 0.3), gap("Potassium", 0.4), gap("Calcium", 0.45)],
            highCount: 1,
            balanceCount: 1
        )
        #expect(recap.shownGaps.map(\.name) == ["Vitamin D", "Vitamin E", "Magnesium"])
        #expect(recap.headline == "You're low on vitamin D, vitamin E and magnesium today")
        #expect(recap.moreLowCount == 2)
        #expect(recap.unnamedCount == 4)
        #expect(recap.unnamedSummary == "2 more running low, 1 over the limit and 1 out of balance")
    }

    @Test func singleGap() {
        let recap = FirstDayRecap(lows: [gap("Folate", 0.2)], highCount: 0, balanceCount: 0)
        #expect(recap.headline == "You're low on folate today")
        #expect(recap.unnamedSummary == nil)
    }

    @Test func noGaps() {
        let recap = FirstDayRecap(lows: [], highCount: 1, balanceCount: 0)
        #expect(recap.shownGaps.isEmpty)
        #expect(recap.headline == "You got at least half of every vitamin and mineral today")
        #expect(recap.unnamedSummary == "1 over the limit")
    }

    @Test func namesReadNaturallyMidSentence() {
        #expect(FirstDayRecap.inSentence("Vitamin B12") == "vitamin B12")
        #expect(FirstDayRecap.inSentence("Pantothenic Acid") == "pantothenic acid")
        #expect(FirstDayRecap.inSentence("Lutein & Zeaxanthin") == "lutein & zeaxanthin")
        #expect(FirstDayRecap.inSentence("Vitamin K") == "vitamin K")
    }

    @Test func showsOnlyOnTheFirstFullDay() {
        #expect(FirstDayRecapTrigger.shouldShow(isFullLoggingDay: true, hasShownBefore: false))
        #expect(!FirstDayRecapTrigger.shouldShow(isFullLoggingDay: false, hasShownBefore: false))
        #expect(!FirstDayRecapTrigger.shouldShow(isFullLoggingDay: true, hasShownBefore: true))
    }

    @Test func fillsInAReferenceAgeOnlyWhenMissing() {
        let noAge = User(gender: .unknown, micronutrientGoals: ["304": 500])
        let filled = noAge.withReferenceAgeIfMissing
        #expect(filled.birthdate != nil)
        #expect(filled.micronutrientGoals == ["304": 500])

        let birthdate = SimpleDate(year: 1980, month: 1, day: 1)
        let withAge = User(birthdate: birthdate)
        #expect(withAge.withReferenceAgeIfMissing.birthdate == birthdate)
    }
}
