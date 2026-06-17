//
//  DateExtensionsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import Testing

struct DateExtensionsTests {

    @Test func formatsRelativeDateStringCorrectly() async throws {
        let clock = MutableClock()
        clock.now = Date.from(year: 2021, month: 10, day: 5)
        
        let tomorrowWednesday = Date.from(year: 2021, month: 10, day: 6)
        let todayTuesday = Date.from(year: 2021, month: 10, day: 5)
        let yesterdayMonday = Date.from(year: 2021, month: 10, day: 4)
        let sunday = Date.from(year: 2021, month: 10, day: 3)
        let saturday = Date.from(year: 2021, month: 10, day: 2)
        let friday = Date.from(year: 2021, month: 10, day: 1)
        let thursday = Date.from(year: 2021, month: 9, day: 30)
        let wednesday = Date.from(year: 2021, month: 9, day: 29)
        let aWeekAgoTuesday = Date.from(year: 2021, month: 9, day: 28)
        let aMonthAgo = Date.from(year: 2021, month: 9, day: 5)
        let aYearAgo = Date.from(year: 2020, month: 10, day: 5)

        #expect("Tomorrow" == tomorrowWednesday.relativeDisplayString(usingClock: clock))
        #expect("Today" == todayTuesday.relativeDisplayString(usingClock: clock))
        #expect("Yesterday" == yesterdayMonday.relativeDisplayString(usingClock: clock))
        #expect("Sunday" == sunday.relativeDisplayString(usingClock: clock))
        #expect("Saturday" == saturday.relativeDisplayString(usingClock: clock))
        #expect("Friday" == friday.relativeDisplayString(usingClock: clock))
        #expect("Thursday" == thursday.relativeDisplayString(usingClock: clock))
        #expect("Wednesday" == wednesday.relativeDisplayString(usingClock: clock))
        #expect("Sep 28, 2021" == aWeekAgoTuesday.relativeDisplayString(usingClock: clock))
        #expect("Sep 5, 2021" == aMonthAgo.relativeDisplayString(usingClock: clock))
        #expect("Oct 5, 2020" == aYearAgo.relativeDisplayString(usingClock: clock))
    }

}
