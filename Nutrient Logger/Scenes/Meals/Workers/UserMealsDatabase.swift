//
//  UserMealsDatabase.swift
//  UserMealsDatabase
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation

public protocol UserMealsDatabase {
    func search(_ query: String) throws -> [UserMealsSearchableMeal]
    func getMeals() throws -> [Meal]
    func saveMeal(_ meal: Meal) throws
    func getMeal(_ id: Int) throws -> Meal
    func saveFood(_ mealFood: Meal.FoodWithPortion, _ meal: Meal) throws
    func saveMealRename(_ mealRename: MealRename) throws
    func deleteMeal(_ mealDelete: MealDelete) throws
    func deleteFood(_ foodDelete: FoodDelete) throws
}
