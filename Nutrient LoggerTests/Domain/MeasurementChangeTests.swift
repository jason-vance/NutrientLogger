//
//  MeasurementChangeTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct MeasurementChangeTests {

    @Test func saysWhichWayItMoved() {
        #expect(MeasurementChange.summary(value: 182.0, unit: "lb", previous: 182.4, previousDay: "Tuesday")
            == "182 lb, down 0.4 since Tuesday")
        #expect(MeasurementChange.summary(value: 183.2, unit: "lb", previous: 182.0, previousDay: "Yesterday")
            == "183.2 lb, up 1.2 since Yesterday")
    }

    @Test func calledTheSameWhenUnderATenth() {
        #expect(MeasurementChange.summary(value: 182.02, unit: "lb", previous: 182.0, previousDay: "Monday")
            == "182 lb, same as Monday")
    }

    @Test func noSpaceBeforeAPercentSign() {
        #expect(MeasurementChange.summary(value: 19.1, unit: "% body fat", previous: 19.5, previousDay: "Yesterday")
            == "19.1% body fat, down 0.4 since Yesterday")
    }

    @Test func justTheValueWithoutAnEarlierEntry() {
        #expect(MeasurementChange.summary(value: 82.5, unit: "kg", previous: nil, previousDay: nil) == "82.5 kg")
    }

    @Test func findsTheLatestEntryBeforeTheDate() {
        let friday = SimpleDate(year: 2026, month: 11, day: 6)!
        let entries: [(SimpleDate, Double)] = [
            (friday.adding(days: -7), 184),
            (friday.adding(days: -3), 182.4),
            (friday, 182.0),
        ]
        let previous = MeasurementChange.previous(before: friday, in: entries, date: { $0.0 }, value: { $0.1 })
        #expect(previous?.date == friday.adding(days: -3))
        #expect(previous?.value == 182.4)
        #expect(MeasurementChange.previous(before: friday.adding(days: -7), in: entries, date: { $0.0 }, value: { $0.1 }) == nil)
    }
}
