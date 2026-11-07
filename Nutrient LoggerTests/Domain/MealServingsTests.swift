//
//  MealServingsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct MealServingsTests {

    @Test func aPlainMealScalesByTheAmountLogged() {
        #expect(Meal.portionMultiplier(servingsEaten: 1, servingsMade: 1) == 1)
        #expect(Meal.portionMultiplier(servingsEaten: 0.5, servingsMade: 1) == 0.5)
    }

    @Test func aBatchDishLogsAShareOfTheBatch() {
        #expect(Meal.portionMultiplier(servingsEaten: 1, servingsMade: 4) == 0.25)
        #expect(Meal.portionMultiplier(servingsEaten: 2, servingsMade: 4) == 0.5)
    }

    @Test func neverDividesByLessThanOneServing() {
        #expect(Meal.portionMultiplier(servingsEaten: 1, servingsMade: 0) == 1)
    }

    @Test func makesTextOnlyForBatchDishes() {
        #expect(Meal.makesText(servings: 1) == nil)
        #expect(Meal.makesText(servings: 6) == "Makes 6 servings")
    }
}
