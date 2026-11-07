//
//  MealRepeat.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Many people eat the same breakfast most days. When a meal is still empty, this finds the last
/// time in the past week that meal had foods, so the dashboard can offer to log them again in one
/// tap ("Repeat yesterday's breakfast").
enum MealRepeat {

    static let lookbackDays = 7

    struct Previous {
        let date: SimpleDate
        let foods: [ConsumedFood]
        let daysBack: Int
    }

    /// The most recent day within the past week before `date` that has foods for `mealTime`.
    static func previous(_ mealTime: MealTime, before date: SimpleDate, in foods: [ConsumedFood]) -> Previous? {
        guard mealTime != .none else { return nil }
        let earliest = date.adding(days: -lookbackDays)
        let candidates = foods.filter { $0.mealTime == mealTime && $0.dateLogged < date && $0.dateLogged >= earliest }
        guard let latest = candidates.map(\.dateLogged).max() else { return nil }
        let dayFoods = candidates
            .filter { $0.dateLogged == latest }
            .sorted { $0.created < $1.created }
        return Previous(date: latest, foods: dayFoods, daysBack: calendarDays(from: latest, to: date))
    }

    /// "Repeat yesterday's breakfast", "Repeat Tuesday's lunch", "Repeat last Friday's dinner".
    static func label(for previous: Previous, mealTime: MealTime, selectedDate: SimpleDate, today: SimpleDate = .today) -> String {
        let meal = mealTime.rawValue.lowercased()
        if previous.daysBack == 1 && selectedDate == today {
            return "Repeat yesterday's \(meal)"
        }
        let weekday = previous.date.toDate().map { weekdayFormatter.string(from: $0) } ?? previous.date.formatted()
        let prefix = previous.daysBack == lookbackDays ? "last " : ""
        return "Repeat \(prefix)\(weekday)'s \(meal)"
    }

    /// New log entries for the same foods and portions, on `date`.
    static func copies(of foods: [ConsumedFood], to date: SimpleDate) -> [ConsumedFood] {
        foods.map {
            ConsumedFood(
                fdcId: $0.fdcId,
                name: $0.name,
                portionAmount: $0.portionAmount,
                portionGramWeight: $0.portionGramWeight,
                portionName: $0.portionName,
                dateLogged: date,
                mealTime: $0.mealTime
            )
        }
    }

    // Counted in calendar days so a 23-hour daylight-saving day still counts as one.
    private static func calendarDays(from start: SimpleDate, to end: SimpleDate) -> Int {
        guard let startDate = start.toDate(), let endDate = end.toDate() else { return lookbackDays }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? lookbackDays
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
