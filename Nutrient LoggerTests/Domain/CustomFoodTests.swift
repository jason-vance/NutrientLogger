//
//  CustomFoodTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/16/26.
//

import XCTest

final class CustomFoodTests: XCTestCase {

    // MARK: - toFoodItem

    func testToFoodItem_setsCorrectFdcId() {
        let food = makeFood(id: -7)
        let item = food.toFoodItem()
        XCTAssertEqual(item.fdcId, -7)
    }

    func testToFoodItem_setsName() {
        let food = makeFood(name: "Test Smoothie")
        let item = food.toFoodItem()
        XCTAssertEqual(item.name, "Test Smoothie")
    }

    func testToFoodItem_setsGramWeight() {
        let food = makeFood(gramWeight: 240)
        let item = food.toFoodItem()
        XCTAssertEqual(item.gramWeight, 240)
    }

    func testToFoodItem_excludesZeroAmountNutrients() {
        let food = makeFood(nutrientAmounts: [
            "208": 200,   // calories — non-zero, should be included
            "203": 0,     // protein — zero, should be excluded
        ])
        let item = food.toFoodItem()
        let allNutrients = item.nutrientGroups.flatMap { $0.nutrients }
        XCTAssertFalse(allNutrients.contains { $0.fdcNumber == "203" },
                       "Zero-amount nutrients should not appear in the FoodItem")
        XCTAssertTrue(allNutrients.contains { $0.fdcNumber == "208" })
    }

    func testToFoodItem_excludesNegativeAmountNutrients() {
        let food = makeFood(nutrientAmounts: ["203": -5])
        let item = food.toFoodItem()
        let allNutrients = item.nutrientGroups.flatMap { $0.nutrients }
        XCTAssertFalse(allNutrients.contains { $0.fdcNumber == "203" })
    }

    func testToFoodItem_partialNutrientsOnly() {
        let food = makeFood(nutrientAmounts: [
            "208": 120,   // calories
            "203": 8,     // protein
        ])
        let item = food.toFoodItem()
        let allNutrients = item.nutrientGroups.flatMap { $0.nutrients }
        XCTAssertEqual(allNutrients.count, 2)
    }

    func testToFoodItem_emptyNutrients() {
        let food = makeFood(nutrientAmounts: [:])
        let item = food.toFoodItem()
        let allNutrients = item.nutrientGroups.flatMap { $0.nutrients }
        XCTAssertTrue(allNutrients.isEmpty)
    }

    func testToFoodItem_nutrientAmountsMatchInput() {
        let food = makeFood(nutrientAmounts: ["208": 350.5])
        let item = food.toFoodItem()
        let calories = item.nutrientGroups
            .flatMap { $0.nutrients }
            .first { $0.fdcNumber == "208" }
        XCTAssertEqual(calories?.amount, 350.5)
    }

    // MARK: - toPortion

    func testToPortion_usesServingUnit() {
        let food = makeFood(servingUnit: "cup", gramWeight: 240)
        let portion = food.toPortion()
        XCTAssertEqual(portion.name, "cup")
        XCTAssertEqual(portion.amount, 1)
        XCTAssertEqual(portion.gramWeight, 240)
    }

    // MARK: - Codable round-trip

    func testCodable_roundTrip() throws {
        let food = makeFood(
            id: -3,
            name: "Custom Oats",
            servingUnit: "cup",
            gramWeight: 80,
            nutrientAmounts: ["208": 300, "203": 10, "205": 54]
        )
        let data = try JSONEncoder().encode(food)
        let decoded = try JSONDecoder().decode(CustomFood.self, from: data)
        XCTAssertEqual(decoded, food)
    }

    func testCodable_partialNutrients() throws {
        let food = makeFood(nutrientAmounts: ["208": 150])
        let data = try JSONEncoder().encode(food)
        let decoded = try JSONDecoder().decode(CustomFood.self, from: data)
        XCTAssertEqual(decoded.nutrientAmounts["208"], 150)
        XCTAssertNil(decoded.nutrientAmounts["203"])
    }

    // MARK: - applyingPortion through FoodItem

    func testPortionScalesNutrients() throws {
        // 1 serving = 100g, 200 kcal.  Apply 2 servings → 200g, 400 kcal.
        let food = makeFood(gramWeight: 100, nutrientAmounts: ["208": 200])
        let item = food.toFoodItem()
        let scaledItem = try item.applyingPortion(Portion(name: "serving", amount: 2, gramWeight: 100))
        let calories = scaledItem.nutrientGroups
            .flatMap { $0.nutrients }
            .first { $0.fdcNumber == "208" }
        XCTAssertEqual(calories?.amount ?? 0, 400, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeFood(
        id: Int = -1,
        name: String = "Test Food",
        servingUnit: String = "serving",
        gramWeight: Double = 100,
        nutrientAmounts: [String: Double] = ["208": 200, "203": 10, "205": 30, "204": 5]
    ) -> CustomFood {
        CustomFood(
            customFoodId: id,
            name: name,
            servingUnit: servingUnit,
            servingGramWeight: gramWeight,
            nutrientAmounts: nutrientAmounts
        )
    }
}
