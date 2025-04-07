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

        #expect("Today" == todayTuesday.relativeDateString(usingClock: clock))
        #expect("Yesterday" == yesterdayMonday.relativeDateString(usingClock: clock))
        #expect("Sunday" == sunday.relativeDateString(usingClock: clock))
        #expect("Saturday" == saturday.relativeDateString(usingClock: clock))
        #expect("Friday" == friday.relativeDateString(usingClock: clock))
        #expect("Thursday" == thursday.relativeDateString(usingClock: clock))
        #expect("Wednesday" == wednesday.relativeDateString(usingClock: clock))
        #expect("28 Sep 2021" == aWeekAgoTuesday.relativeDateString(usingClock: clock))
        #expect("5 Sep 2021" == aMonthAgo.relativeDateString(usingClock: clock))
        #expect("5 Oct 2020" == aYearAgo.relativeDateString(usingClock: clock))
    }

}
