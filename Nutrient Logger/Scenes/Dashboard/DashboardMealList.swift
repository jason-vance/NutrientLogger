//
//  DashboardMealList.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum DashboardMealList {
    
    public static func from(_ foods: [ConsumedFood]) -> [Meal] {
        let meals: [MealTime: Meal] = [
            .none: .init(),
            .breakfast: .init(),
            .lunch: .init(),
            .dinner: .init(),
            .eveningSnack: .init(),
            .morningSnack: .init(),
        ]
        
        for food in foods {
            meals[food.mealTime, default: .init()].append(food)
        }

        return meals.compactMap {
            $0.value.foods.count > 0 ? $0.value : nil
        }
    }
    
    public class Meal: Identifiable {
        
        private(set) var foods: [ConsumedFood] = []
        
        var mealTime: MealTime { foods.first?.mealTime ?? .none }
        
        public var name: String { mealTime.rawValue }

        public func append(_ food: ConsumedFood) {
            foods.append(food)
        }
    }
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
