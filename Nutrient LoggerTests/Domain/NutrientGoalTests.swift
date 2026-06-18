//
//  NutrientGoalTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/17/26.
//

import Foundation
import Testing

struct NutrientGoalTests {

    // MARK: - Default calorie goals by gender

    @Test func defaultCalorieGoalForMale() {
        let user = User(gender: .male)
        #expect(NutrientGoalDefaults.defaultCalorieGoal(for: user) == 2500)
    }

    @Test func defaultCalorieGoalForFemale() {
        let user = User(gender: .female)
        #expect(NutrientGoalDefaults.defaultCalorieGoal(for: user) == 2000)
    }

    @Test func defaultCalorieGoalForUnknownGender() {
        let user = User(gender: .unknown)
        #expect(NutrientGoalDefaults.defaultCalorieGoal(for: user) == 2000)
    }

    // MARK: - Default macro goals derived from calorie default

    @Test func defaultMacroGoalsForFemale() {
        let user = User(gender: .female)
        let carbs = NutrientGoalDefaults.defaultCarbsGoal(for: user)
        let fat = NutrientGoalDefaults.defaultFatGoal(for: user)
        let protein = NutrientGoalDefaults.defaultProteinGoal(for: user)

        #expect(carbs == 250)
        #expect(fat == 67)
        #expect(protein == 100)
    }

    @Test func defaultMacroGoalsForMale() {
        let user = User(gender: .male)
        let carbs = NutrientGoalDefaults.defaultCarbsGoal(for: user)
        let fat = NutrientGoalDefaults.defaultFatGoal(for: user)
        let protein = NutrientGoalDefaults.defaultProteinGoal(for: user)

        #expect(carbs == 313)
        #expect(fat == 83)
        #expect(protein == 125)
    }

    // MARK: - Macro defaults adjust when custom calorie goal is set

    @Test func macroDefaultsAdjustToCustomCalorieGoal() {
        var user = User(gender: .female)
        user.calorieGoal = 1500

        let carbs = NutrientGoalDefaults.defaultCarbsGoal(for: user)
        let fat = NutrientGoalDefaults.defaultFatGoal(for: user)
        let protein = NutrientGoalDefaults.defaultProteinGoal(for: user)

        #expect(carbs == 188)
        #expect(fat == 50)
        #expect(protein == 75)
    }

    // MARK: - Custom goal overrides default (precedence)

    @Test func customCalorieGoalOverridesDefault() {
        var user = User(gender: .female)
        user.calorieGoal = 1800

        let effectiveGoal = user.calorieGoal ?? NutrientGoalDefaults.defaultCalorieGoal(for: user)
        #expect(effectiveGoal == 1800)
    }

    @Test func nilCalorieGoalFallsBackToDefault() {
        let user = User(gender: .male)

        let effectiveGoal = user.calorieGoal ?? NutrientGoalDefaults.defaultCalorieGoal(for: user)
        #expect(effectiveGoal == 2500)
    }

    @Test func customMacroGoalOverridesDefault() {
        var user = User(gender: .female)
        user.carbsGoalGrams = 200
        user.fatGoalGrams = 55
        user.proteinGoalGrams = 130

        let effectiveCarbs = user.carbsGoalGrams ?? NutrientGoalDefaults.defaultCarbsGoal(for: user)
        let effectiveFat = user.fatGoalGrams ?? NutrientGoalDefaults.defaultFatGoal(for: user)
        let effectiveProtein = user.proteinGoalGrams ?? NutrientGoalDefaults.defaultProteinGoal(for: user)

        #expect(effectiveCarbs == 200)
        #expect(effectiveFat == 55)
        #expect(effectiveProtein == 130)
    }

    @Test func nilMacroGoalsFallBackToDefaults() {
        let user = User(gender: .female)

        let effectiveCarbs = user.carbsGoalGrams ?? NutrientGoalDefaults.defaultCarbsGoal(for: user)
        let effectiveFat = user.fatGoalGrams ?? NutrientGoalDefaults.defaultFatGoal(for: user)
        let effectiveProtein = user.proteinGoalGrams ?? NutrientGoalDefaults.defaultProteinGoal(for: user)

        #expect(effectiveCarbs == 250)
        #expect(effectiveFat == 67)
        #expect(effectiveProtein == 100)
    }

    // MARK: - Goals survive JSON round-trip (backward compatibility)

    @Test func goalsEncodeAndDecode() throws {
        var user = User(gender: .male)
        user.calorieGoal = 2200
        user.carbsGoalGrams = 275
        user.fatGoalGrams = 73
        user.proteinGoalGrams = 110

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        #expect(decoded.calorieGoal == 2200)
        #expect(decoded.carbsGoalGrams == 275)
        #expect(decoded.fatGoalGrams == 73)
        #expect(decoded.proteinGoalGrams == 110)
    }

    @Test func decodingOldUserWithoutGoalsSucceeds() throws {
        let user = User(gender: .female)
        let data = try JSONEncoder().encode(user)

        // Re-decode the data produced by a pre-goals User — the new optional
        // fields should default to nil without crashing.
        let decoded = try JSONDecoder().decode(User.self, from: data)

        #expect(decoded.gender == Gender.female)
        #expect(decoded.calorieGoal == nil)
        #expect(decoded.carbsGoalGrams == nil)
        #expect(decoded.fatGoalGrams == nil)
        #expect(decoded.proteinGoalGrams == nil)
        #expect(decoded.micronutrientGoals.isEmpty)
    }

    // MARK: - Micronutrient goal overrides RDI

    @Test func effectiveRdiReturnsLibraryRdiWhenNoCustomGoal() {
        let user = User.sample
        let rdiLibrary = UsdaNutrientRdiLibrary.create()
        let calciumId = FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca

        let effective = NutrientGoalDefaults.effectiveRdi(
            for: calciumId,
            user: user,
            rdiLibrary: rdiLibrary
        )
        let library = rdiLibrary.getRdis(calciumId)?.getRdi(user)

        #expect(effective != nil)
        #expect(library != nil)
        #expect(effective!.recommendedAmount == library!.recommendedAmount)
        #expect(effective!.upperLimit == library!.upperLimit)
    }

    @Test func effectiveRdiReturnsCustomGoalWhenSet() {
        var user = User.sample
        let rdiLibrary = UsdaNutrientRdiLibrary.create()
        let calciumId = FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca

        user.micronutrientGoals[calciumId] = 1500

        let effective = NutrientGoalDefaults.effectiveRdi(
            for: calciumId,
            user: user,
            rdiLibrary: rdiLibrary
        )

        #expect(effective != nil)
        #expect(effective!.recommendedAmount == 1500)
    }

    @Test func effectiveRdiPreservesUpperLimitFromLibrary() {
        var user = User.sample
        let rdiLibrary = UsdaNutrientRdiLibrary.create()
        let calciumId = FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca

        let libraryRdi = rdiLibrary.getRdis(calciumId)?.getRdi(user)
        user.micronutrientGoals[calciumId] = 1500

        let effective = NutrientGoalDefaults.effectiveRdi(
            for: calciumId,
            user: user,
            rdiLibrary: rdiLibrary
        )

        #expect(effective!.upperLimit == libraryRdi!.upperLimit)
    }

    @Test func effectiveRdiPreservesUnitFromLibrary() {
        var user = User.sample
        let rdiLibrary = UsdaNutrientRdiLibrary.create()
        let calciumId = FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca

        let libraryRdi = rdiLibrary.getRdis(calciumId)?.getRdi(user)
        user.micronutrientGoals[calciumId] = 1500

        let effective = NutrientGoalDefaults.effectiveRdi(
            for: calciumId,
            user: user,
            rdiLibrary: rdiLibrary
        )

        #expect(effective!.unit == libraryRdi!.unit)
    }

    @Test func effectiveRdiReturnsNilForUnknownNutrientWithNoGoal() {
        let user = User.sample
        let rdiLibrary = UsdaNutrientRdiLibrary.create()

        let effective = NutrientGoalDefaults.effectiveRdi(
            for: "99999",
            user: user,
            rdiLibrary: rdiLibrary
        )

        #expect(effective == nil)
    }

    @Test func micronutrientGoalsSurviveJsonRoundTrip() throws {
        var user = User(gender: .male)
        user.micronutrientGoals["301"] = 1500
        user.micronutrientGoals["303"] = 20

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        #expect(decoded.micronutrientGoals["301"] == 1500)
        #expect(decoded.micronutrientGoals["303"] == 20)
    }
}
