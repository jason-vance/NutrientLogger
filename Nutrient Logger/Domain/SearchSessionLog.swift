//
//  SearchSessionLog.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import Foundation

/// The foods logged since the search screen opened, so a user logging a whole day can check
/// what they've added ("Did I include the banana?") and fix mistakes without leaving search.
enum SearchSessionLog {

    struct Group<Item>: Identifiable {
        let date: SimpleDate
        let mealTime: MealTime
        let items: [Item]

        var id: String { "\(date)-\(mealTime.rawValue)" }
    }

    /// The newest names first, e.g. "Coffee, Toast, Eggs +2".
    static func namesSummary(newestFirst names: [String], limit: Int = 3) -> String {
        let shown = names.prefix(limit).joined(separator: ", ")
        let extra = names.count - min(names.count, limit)
        return extra > 0 ? "\(shown) +\(extra)" : shown
    }

    /// Foods grouped by day and meal, in the order you'd eat them. Each group keeps the order the
    /// items were given in.
    static func groups<Item>(
        _ items: [Item],
        date: (Item) -> SimpleDate,
        mealTime: (Item) -> MealTime
    ) -> [Group<Item>] {
        var order: [String] = []
        var buckets: [String: Group<Item>] = [:]
        for item in items {
            let key = "\(date(item))-\(mealTime(item).rawValue)"
            if let existing = buckets[key] {
                buckets[key] = Group(date: existing.date, mealTime: existing.mealTime, items: existing.items + [item])
            } else {
                order.append(key)
                buckets[key] = Group(date: date(item), mealTime: mealTime(item), items: [item])
            }
        }
        return order
            .compactMap { buckets[$0] }
            .sorted { ($0.date, $0.mealTime.order) < ($1.date, $1.mealTime.order) }
    }

    /// "Breakfast" for today, "Breakfast · Yesterday" for any other day.
    static func title(date: SimpleDate, mealTime: MealTime, today: SimpleDate, dayName: String) -> String {
        date == today ? mealTime.rawValue : "\(mealTime.rawValue) · \(dayName)"
    }
}
