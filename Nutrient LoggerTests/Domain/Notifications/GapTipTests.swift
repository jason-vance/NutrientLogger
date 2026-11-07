//
//  GapTipTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation
import Testing

struct GapTipTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    @Test func firesTheNextMorningAfterAFullDay() {
        let fire = GapTip.fireDate(now: date(6, 20), isFullLoggingDay: true, enabled: true, calendar: calendar)
        #expect(fire == date(7, 9))
    }

    @Test func waitsForAFullDayAndRespectsTheSetting() {
        #expect(GapTip.fireDate(now: date(6, 20), isFullLoggingDay: false, enabled: true, calendar: calendar) == nil)
        #expect(GapTip.fireDate(now: date(6, 20), isFullLoggingDay: true, enabled: false, calendar: calendar) == nil)
    }

    @Test func namesTheGapAndFoodsThatHelp() {
        #expect(GapTip.body(lowNames: ["Magnesium", "Vitamin C"], foods: "pumpkin seeds (1 oz) or almonds (1 oz)")
            == "You were low on magnesium yesterday. Pumpkin seeds (1 oz) or almonds (1 oz) would help today.")
    }

    @Test func withoutFoodsNamesUpToTwoGaps() {
        #expect(GapTip.body(lowNames: ["Vitamin D", "Vitamin E", "Folate"], foods: nil)
            == "You were low on vitamin D and vitamin E yesterday. Open Nutrient Logger to see what helps.")
        #expect(GapTip.body(lowNames: [], foods: nil) == nil)
    }
}
