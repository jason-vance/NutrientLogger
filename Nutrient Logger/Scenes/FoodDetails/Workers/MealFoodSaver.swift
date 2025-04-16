//
//  MealFoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SwinjectAutoregistration

class MealFoodSaverDelegate: FoodSaverDelegate {

    private let unknownId = -1

    public var needsPortion: Bool { true }
    
    public var needsDateTime: Bool { false }
    
    public let meal: Meal
    private let db: UserMealsDatabase
    private let analytics: UserMealAnalytics?
    
    public init(
        meal: Meal,
        db: UserMealsDatabase,
        analytics: UserMealAnalytics?
    ) {
        self.meal = meal
        self.db = db
        self.analytics = analytics
    }
    
    public func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws {
        if (meal.id == unknownId) {
            throw FoodSaverErrors.mealIdNotSet
        }
        
        do {
            let mealFood = foodWithPortionFrom(food, portion)
            try db.saveFood(mealFood, meal)
            analytics?.foodAddedToMeal(food)
        } catch {
            analytics?.addFoodToMealFailed(food)
            throw error
        }
    }
    
    private func foodWithPortionFrom(_ food: FoodItem, _ portion: Portion) -> Meal.FoodWithPortion {
        return Meal.FoodWithPortion(
            mealId: meal.id,
            foodFdcId: food.fdcId,
            foodName: food.name,
            portionAmount: portion.amount,
            portionGramWeight: portion.gramWeight,
            portionName: portion.name
        )
    }
}

extension FoodSaver {
    static func forMeal(_ meal: Meal) -> FoodSaver {
        FoodSaver(
            delegate: MealFoodSaverDelegate(
                meal: meal,
                db: swinjectContainer~>UserMealsDatabase.self,
                analytics: swinjectContainer~>UserMealAnalytics.self
            )
        )
    }
}
