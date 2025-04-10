//
//  UserMealsDatabaseForScreenshots.swift
//  UserMealsDatabaseForScreenshots
//
//  Created by Jason Vance on 9/21/21.
//

import Foundation

public class UserMealsDatabaseForScreenshots: UserMealsDatabase {
    
    public func search(_ query: String) throws -> [UserMealsSearchableMeal] {
        [
            .init(
                mealId: 4,
                foodId: 4,
                mealName: "Usual Weekday Breakfast",
                foodName: "Usual Weekday Breakfast",
                rank: 0
            )
        ]
    }
    
    public func getMenu() throws -> Menu {
        var meals = [Meal]()
        meals.append(Meal(id: 4, name: "Usual Weekday Breakfast" ))
        meals.append(Meal(id: 5, name: "Ultimate BLT" ))
        meals.append(Meal(id: 3, name: "Chicken Pasta Dinner" ))
        meals.append(try getMeal(0))

        let menu = Menu()
        menu.add(meals)

        return menu
    }
    
    public func saveMeal(_ meal: Meal) throws {}
    
    public func getMeal(_ id: Int) throws -> Meal {
        var meal = Meal(id: 6, name: "Post-workout Shake")

        meal.addFood(Meal.FoodWithPortion(
            mealId: 0,
            foodFdcId: 0,
            foodName: "Milk, whole",
            portionAmount: 1,
            portionGramWeight: 1,
            portionName: "cup")
            .withId(0))
        meal.addFood(Meal.FoodWithPortion(
            mealId: 0,
            foodFdcId: 0,
            foodName: "Beverages, Whey protein powder isolate",
            portionAmount: 1,
            portionGramWeight: 1,
            portionName: "scoop")
            .withId(2))
        meal.addFood(Meal.FoodWithPortion(
            mealId: 0,
            foodFdcId: 0,
            foodName: "Spinach, raw",
            portionAmount: 1,
            portionGramWeight: 1,
            portionName: "cup")
            .withId(4))
        meal.addFood(Meal.FoodWithPortion(
            mealId: 0,
            foodFdcId: 0,
            foodName: "Peanut butter",
            portionAmount: 1,
            portionGramWeight: 1,
            portionName: "tablespoon")
            .withId(3))
        meal.addFood(Meal.FoodWithPortion(
            mealId: 0,
            foodFdcId: 0,
            foodName: "Banana, raw",
            portionAmount: 0.5,
            portionGramWeight: 1,
            portionName: "banana")
            .withId(1))

        return meal
    }
    
    public func saveFood(_ mealFood: Meal.FoodWithPortion, _ meal: Meal) throws {}
    
    public func saveMealRename(_ mealRename: MealRename) throws {}
    
    public func deleteMeal(_ mealDelete: MealDelete) throws {}
    
    public func deleteFood(_ foodDelete: FoodDelete) throws {}
}
