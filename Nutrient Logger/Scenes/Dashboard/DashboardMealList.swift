//
//  DashboardMealList.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class DashboardMealList {
    private var meals: [Meal] = []
    
    public static func from(_ foods: [FoodItem]) -> [Meal] {
        let avgTimeBetweenFoods = DashboardMealList.averageTimeBetweenFoods(foods)

        let mealList = DashboardMealList()

        var prev: FoodItem? = nil
        for food in foods {
            if (prev == nil) {
                mealList.append(DashboardMealList.Meal())
                mealList.last!.append(food)
            } else {
                let timeBetweenFoods = DatabaseDate.from(food.dateLogged) - DatabaseDate.from(prev!.dateLogged)
                if (timeBetweenFoods >= avgTimeBetweenFoods) {
                    mealList.append(DashboardMealList.Meal())
                }
                mealList.last!.append(food)
            }
            prev = food
        }

        return mealList.meals
    }
    
    private static func averageTimeBetweenFoods(_ foods: [FoodItem]) -> DatabaseDate {
        if (foods.count < 2) {
            return 0
        }

        var avgTimeBetweenFoods: DatabaseDate = 0
        for i in 1..<foods.count {
            let prev = foods[i - 1]
            let current = foods[i]
            avgTimeBetweenFoods += DatabaseDate.from(current.dateLogged) - DatabaseDate.from(prev.dateLogged)
        }
        avgTimeBetweenFoods /= Int64(foods.count - 1)
        return avgTimeBetweenFoods
    }
    
    public func append(_ meal: Meal) {
        meals.append(meal)
    }
    
    public var last: Meal? { meals.last }
    
    public class Meal: Identifiable {
        
        private(set) var foods: [FoodItem] = []
        
        public var name: String {
            let name = (timeSpecification + " " + sizeSpecification)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if name.isEmpty {
                return("Meal")
            }
            return name
        }
        
        private var timeSpecification: String {
            guard let firstFood = foods.first else { return "" }
            
            let timeOfDay = firstFood.dateLogged.timeOfDay
            
            if timeOfDay < TimeInterval.fromHours(10) { //12am - 10am
                return "Morning"
            }
            if timeOfDay < TimeInterval.fromHours(11.75) { //10am - 11:45am
                return "Late Morning"
            }
            if timeOfDay < TimeInterval.fromHours(13.5) { //11:45am - 1:30pm
                return "Mid Day"
            }
            if timeOfDay < TimeInterval.fromHours(17) { //1:30pm - 5pm
                return "Afternoon"
            }
            if timeOfDay < TimeInterval.fromHours(20) { //5pm - 8pm
                return "Evening"
            }
            return "Nighttime"
        }
        
        private var sizeSpecification: String {
            let calories = foods.reduce(0.0) { sum, food in
                guard let calories = food.nutrientGroups
                        .first(where: { group in group.fdcNumber == FdcNutrientGroupMapper.GroupNumber_Proximates })?
                        .nutrients
                        .first(where: { nutrient in nutrient.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Energy_KCal })?
                        .amount
                else { return sum }
                
                return sum + calories
            }
            
            if (calories < 300) {
                return "Snack"
            }
            return "Meal"
        }

        public func append(_ food: FoodItem) {
            foods.append(food)
        }
    }
}
