//
//  FoodItemTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Testing

struct FoodItemTests {
    
    @Test public func testApplyPortions() { applyPortions(1, 1, 1, 1, 1) }
    @Test public func testApplyPortions_FoodAmount() { applyPortions(10, 1, 1, 1, 1) }
    @Test public func testApplyPortions_FoodGrams() { applyPortions(1, 10, 1, 1, 0.1) }
    @Test public func testApplyPortions_PortionAmount() { applyPortions(1, 1, 10, 1, 10) }
    @Test public func testApplyPortions_PortionGrams() { applyPortions(1, 10, 1, 1, 0.1) }

    public func applyPortions(_ foodAmount: Double, _ foodGramWeight: Double, _ portionAmount: Double, _ portionGramWeight: Double, _ expected: Double) {
        let protein = Nutrient(
            fdcId: 203,
            fdcNumber: "203",
            name: "Protein",
            unitName: WeightUnit.milligram.name,
            amount: 1
        )

        var proximateNutrients = [Nutrient]()
        proximateNutrients.append(protein)

        var groups = [NutrientGroup]()
        groups.append(NutrientGroup(
            fdcNumber: "951",
            name: "Proximates",
            nutrients: proximateNutrients
        ))

        let food = FoodItem(
            nutrientGroups: groups,
            amount: foodAmount,
            gramWeight: foodGramWeight
        )

        let portion = Portion(
            amount: portionAmount,
            gramWeight: portionGramWeight
        )

        try! food.applyPortion(portion)
        let proteinAmount = food.nutrientGroups.flatMap { $0.nutrients }[0].amount

        #expect(expected == proteinAmount)
    }
}
