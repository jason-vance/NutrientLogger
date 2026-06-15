//
//  FullLoggingDay.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation

enum FullLoggingDay {

    /// The meal times that must each have at least one logged food for a day to count as "full."
    static let requiredMealTimes: [MealTime] = [.breakfast, .lunch, .dinner]

    /// Returns whether `foods` includes at least one entry for `date` in each of `requiredMealTimes`.
    static func isComplete(_ foods: [ConsumedFood], on date: SimpleDate) -> Bool {
        let loggedMealTimes = Set(
            foods
                .filter { $0.dateLogged == date }
                .map { $0.mealTime }
        )

        return requiredMealTimes.allSatisfy { loggedMealTimes.contains($0) }
    }
}
