//
//  MeasurementChange.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Reads a new body measurement against the previous one, so the save button says what the entry
/// means ("182 lb, down 0.4 since Tuesday") rather than just "Save".
enum MeasurementChange {

    /// "182.0 lb, down 0.4 since Tuesday", "182.0 lb, same as Tuesday", or just "182.0 lb" when
    /// there's nothing earlier to compare with.
    static func summary(value: Double, unit: String, previous: Double?, previousDay: String?) -> String {
        let current = withUnit(value, unit)
        guard let previous, let previousDay else { return current }
        let difference = (value - previous) * 10
        let rounded = difference.rounded() / 10
        if rounded == 0 { return "\(current), same as \(previousDay)" }
        let direction = rounded > 0 ? "up" : "down"
        return "\(current), \(direction) \(abs(rounded).formatted(maxDigits: 1)) since \(previousDay)"
    }

    /// "182 lb", "19.5%" (no space before a percent sign).
    static func withUnit(_ value: Double, _ unit: String) -> String {
        "\(value.formatted(maxDigits: 1))\(unit.hasPrefix("%") ? "" : " ")\(unit)"
    }

    /// The most recent entry before `date`, as (date, value).
    static func previous<Entry>(
        before date: SimpleDate,
        in entries: [Entry],
        date entryDate: (Entry) -> SimpleDate,
        value: (Entry) -> Double
    ) -> (date: SimpleDate, value: Double)? {
        entries
            .filter { entryDate($0) < date }
            .max { entryDate($0) < entryDate($1) }
            .map { (entryDate($0), value($0)) }
    }
}
