//
//  DashboardMealList.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum DashboardMealList {

    // Always includes every valid meal time, even ones with no logged foods yet, so callers can
    // show an empty "Breakfast" card (etc.) as an invitation to log rather than hiding it. Foods
    // logged under the legacy/edge-case `.none` meal time still get their own card, but only when
    // they actually exist.
    public static func from(_ foods: [ConsumedFood]) -> [Meal] {
        var meals: [MealTime: Meal] = [:]
        for mealTime in MealTime.validFields {
            meals[mealTime] = Meal(mealTime: mealTime)
        }

        for food in foods {
            meals[food.mealTime, default: Meal(mealTime: food.mealTime)].append(food)
        }

        return meals.values.sorted { $0.mealTime < $1.mealTime }
    }

    public class Meal: Identifiable {

        public let mealTime: MealTime
        private(set) var foods: [ConsumedFood] = []

        public var id: MealTime { mealTime }
        public var name: String { mealTime.rawValue }

        public init(mealTime: MealTime = .none) {
            self.mealTime = mealTime
        }

        public func append(_ food: ConsumedFood) {
            foods.append(food)
        }
    }
}

extension DashboardMealList.Meal {
    static let sample: DashboardMealList.Meal = {
        let meal = DashboardMealList.Meal(mealTime: .breakfast)
        meal.append(.dashboardSample)
        return meal
    }()
}

extension DashboardMealList.Meal: Comparable {
    static func == (lhs: DashboardMealList.Meal, rhs: DashboardMealList.Meal) -> Bool {
        lhs.mealTime == rhs.mealTime
        && lhs.foods == rhs.foods
    }

    static func < (lhs: DashboardMealList.Meal, rhs: DashboardMealList.Meal) -> Bool {
        lhs.mealTime < rhs.mealTime
    }
}

extension DashboardMealList.Meal: Hashable {
    // Only needs to be consistent with `==`, not fully distinguish every unequal instance, so
    // hashing on `mealTime` alone (there's only ever one Meal per meal time) is sufficient.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mealTime)
    }
}
