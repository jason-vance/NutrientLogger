//
//  DashboardMealList.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum DashboardMealList {
    
    public static func from(_ foods: [FoodItem]) -> [Meal] {
        let meals = [MealTime: Meal]()
        
        for food in foods {
            meals[food.mealTime ?? .none, default: .init()].append(food)
        }

        return meals.map { $0.value }
    }
    
    public class Meal: Identifiable {
        
        private(set) var foods: [FoodItem] = []
        
        public var name: String {
            foods.first?.mealTime?.rawValue ?? "<Unnamed Meal>"
        }

        public func append(_ food: FoodItem) {
            foods.append(food)
        }
    }
}
