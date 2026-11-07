//
//  FoodBreakdownTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/7/26.
//

import Testing

struct FoodBreakdownTests {

    private let goals: [String: Double] = ["b12": 2.4, "zinc": 11, "iron": 8, "vitC": 90, "folate": 400, "mg": 400]
    private let micros = ["b12", "zinc", "iron", "vitC", "folate", "mg"]

    private func make(_ amounts: [String: Double], gaps: [String] = [], richCount: Int = 6) -> FoodBreakdown {
        FoodBreakdown.make(amounts: amounts, goal: { goals[$0] }, micronutrients: micros, gaps: gaps, richCount: richCount)
    }

    @Test func ranksRichestNutrientsFirst() {
        // A steak: lots of B12 and zinc, some iron.
        let breakdown = make(["b12": 4.8, "zinc": 11, "iron": 2])
        #expect(breakdown.richIn.map(\.fdcNumber) == ["b12", "zinc", "iron"])
        #expect(breakdown.richIn.first?.percentOfGoal == 2)
    }

    @Test func leavesOutTraceAmounts() {
        let breakdown = make(["b12": 2.4, "iron": 0.4])  // iron at 5% of goal
        #expect(breakdown.richIn.map(\.fdcNumber) == ["b12"])
    }

    @Test func capsTheRichList() {
        let breakdown = make(["b12": 2.4, "zinc": 11, "iron": 8], richCount: 2)
        #expect(breakdown.richIn.count == 2)
    }

    @Test func flagsGapsTheFoodBarelyTouches() {
        // Carnivore gaps: vitamin C is absent, folate is a trace, magnesium is a fair share.
        let breakdown = make(["b12": 4.8, "folate": 12, "mg": 60], gaps: ["vitC", "folate", "mg"])
        #expect(breakdown.lowIn.map(\.fdcNumber) == ["vitC", "folate"])
    }

    @Test func keepsGapsOutOfTheRichList() {
        let breakdown = make(["mg": 200], gaps: ["mg"])
        #expect(breakdown.richIn.isEmpty)
        #expect(breakdown.lowIn.isEmpty)
    }

    @Test func skipsNutrientsWithNoGoal() {
        let breakdown = make(["b12": 2.4, "caffeine": 95], gaps: ["caffeine"])
        #expect(breakdown.richIn.map(\.fdcNumber) == ["b12"])
        #expect(breakdown.lowIn.isEmpty)
    }

    @Test func countsEveryReportedNutrient() {
        let breakdown = make(["b12": 2.4, "protein": 30, "fat": 12, "vitC": 0])
        #expect(breakdown.nutrientCount == 3)
    }
}
