//
//  GapTip.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// A morning reminder after a full logged day that names the day's biggest gap and foods that
/// help: "You were low on magnesium yesterday. Pumpkin seeds (1 oz) or almonds (1 oz) would help
/// today." It gives a reason to open the app tomorrow, not just a nudge to log.
enum GapTip {

    static let hour = 9
    static let title = "Yesterday's nutrient gap"

    /// Tomorrow at `hour`, but only after a full day (breakfast, lunch and dinner), so the gap
    /// isn't just a meal that hasn't been logged yet.
    static func fireDate(now: Date, isFullLoggingDay: Bool, enabled: Bool, calendar: Calendar = .current) -> Date? {
        guard enabled, isFullLoggingDay,
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)
        else { return nil }
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow)
    }

    /// `lowNames` are lowest first. `foods` is the `GapFoods.sentence` for the first one.
    static func body(lowNames: [String], foods: String?) -> String? {
        guard let first = lowNames.first else { return nil }
        let lowest = FirstDayRecap.inSentence(first)
        if let foods {
            return "You were low on \(lowest) yesterday. \(foods.prefix(1).uppercased() + foods.dropFirst()) would help today."
        }
        let names = FirstDayRecap.naturalList(lowNames.prefix(2).map(FirstDayRecap.inSentence))
        return "You were low on \(names) yesterday. Open Nutrient Logger to see what helps."
    }
}
