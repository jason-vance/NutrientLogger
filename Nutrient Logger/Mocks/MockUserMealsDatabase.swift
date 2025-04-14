//
//  MockUserMealsDatabase.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class MockUserMealsDatabase: UserMealsDatabase {
    
    public var savedMeals = [Meal]()
    public var savedFoods = [Meal.FoodWithPortion]()
    public var savedMealRenames = [MealRename]()
    public var savedMealDeletes = [MealDelete]()
    public var savedFoodDeletes = [FoodDelete]()

    public var mealToReturnForGetMeal = Meal(name: "Meal")
    
    public var errorToThrow: Error?
    
    public func search(_ query: String) throws -> [UserMealsSearchableMeal] { [] }
    
    public func getMeals() throws -> [Meal] {
        if let error = errorToThrow {
            throw error
        }
        return [mealToReturnForGetMeal]
    }

    public func saveMeal(_ meal: Meal) throws {
        if let error = errorToThrow {
            throw error
        }
        savedMeals.append(meal)
    }

    public func getMeal(_ id: Int) throws -> Meal {
        if let error = errorToThrow {
            throw error
        }
        return mealToReturnForGetMeal
    }

    public func saveFood(_ mealFood: Meal.FoodWithPortion, _ meal: Meal) throws {
        if let error = errorToThrow {
            throw error
        }
        savedFoods.append(mealFood)
    }

    public func saveMealRename(_ mealRename: MealRename) throws {
        if let error = errorToThrow {
            throw error
        }
        savedMealRenames.append(mealRename)
    }

    public func deleteMeal(_ mealDelete: MealDelete) throws {
        if let error = errorToThrow {
            throw error
        }
        savedMealDeletes.append(mealDelete)
    }

    public func deleteFood(_ foodDelete: FoodDelete) throws {
        if let error = errorToThrow {
            throw error
        }
        savedFoodDeletes.append(foodDelete)
    }
}
