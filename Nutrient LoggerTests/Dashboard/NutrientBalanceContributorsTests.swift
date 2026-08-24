//
//  NutrientBalanceContributorsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 8/24/26.
//

import Foundation
import Testing

struct NutrientBalanceContributorsTests {

    private let linoleic = FdcNutrientGroupMapper.NutrientNumber_18_2
    private let arachidonic = FdcNutrientGroupMapper.NutrientNumber_20_4
    private let epa = FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA
    private let dha = FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA

    // MARK: - topFoods

    @Test func noDataForTheSideYieldsNoContributors() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [:]
        )

        #expect(foods.isEmpty)
    }

    @Test func contributorsAreRankedLargestFirst() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [
                linoleic: ["Almonds": 3, "Sunflower oil": 12, "Chicken": 1]
            ]
        )

        #expect(foods.map(\.foodName) == ["Sunflower oil", "Almonds", "Chicken"])
    }

    @Test func aFoodSpanningSeveralNutrientsOnTheSideIsSummedOnce() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [epa, dha],
            gramsByNutrientAndFood: [
                epa: ["Salmon": 0.7],
                dha: ["Salmon": 1.1, "Walnuts": 0.4]
            ]
        )

        #expect(foods.count == 2)
        #expect(foods[0].foodName == "Salmon")
        #expect(abs(foods[0].grams - 1.8) < 0.0001)
    }

    @Test func sharesAreFractionsOfTheSideTotal() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [linoleic: ["Sunflower oil": 6, "Almonds": 2]]
        )

        #expect(abs(foods[0].share - 0.75) < 0.0001)
        #expect(abs(foods[1].share - 0.25) < 0.0001)
    }

    @Test func nutrientsOutsideTheSideAreIgnored() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [
                linoleic: ["Sunflower oil": 6],
                epa: ["Salmon": 99]
            ]
        )

        #expect(foods.map(\.foodName) == ["Sunflower oil"])
    }

    @Test func theListIsCappedAtTheRequestedLimit() {
        let amounts = Dictionary(
            uniqueKeysWithValues: (1...10).map { ("Food \($0)", Double($0)) }
        )

        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [linoleic: amounts],
            limit: 3
        )

        #expect(foods.count == 3)
        #expect(foods.map(\.foodName) == ["Food 10", "Food 9", "Food 8"])
    }

    @Test func tiedContributorsAreOrderedByNameSoTheListIsStable() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [linoleic: ["Walnuts": 5, "Almonds": 5, "Pecans": 5]]
        )

        #expect(foods.map(\.foodName) == ["Almonds", "Pecans", "Walnuts"])
    }

    @Test func zeroAmountFoodsAreLeftOut() {
        let foods = NutrientBalanceContributors.topFoods(
            nutrientIds: [linoleic],
            gramsByNutrientAndFood: [linoleic: ["Sunflower oil": 6, "Water": 0]]
        )

        #expect(foods.map(\.foodName) == ["Sunflower oil"])
    }

    // MARK: - contributions(for:)

    @Test func contributionsSplitTheRatioIntoItsTwoSides() {
        let ratio = NutrientBalanceDefaults.all.first { $0.id == NutrientBalanceDefaults.omega6Omega3Id }!

        let contributions = NutrientBalanceContributors.contributions(
            for: ratio,
            gramsByNutrientAndFood: [
                linoleic: ["Sunflower oil": 12],
                arachidonic: ["Chicken": 0.2],
                epa: ["Salmon": 0.7],
                dha: ["Salmon": 1.1]
            ]
        )

        #expect(contributions.numerator.map(\.foodName) == ["Sunflower oil", "Chicken"])
        #expect(contributions.denominator.map(\.foodName) == ["Salmon"])
        #expect(!contributions.isEmpty)
    }

    @Test func contributionsAreEmptyWhenNothingWasLogged() {
        let ratio = NutrientBalanceDefaults.all.first { $0.id == NutrientBalanceDefaults.omega6Omega3Id }!

        let contributions = NutrientBalanceContributors.contributions(
            for: ratio,
            gramsByNutrientAndFood: [:]
        )

        #expect(contributions.isEmpty)
    }

    // MARK: - Amount formatting

    @Test func gramScaleAmountsShowAsGrams() {
        #expect(NutrientContribution.format(grams: 12.34) == "12.3 g")
        #expect(NutrientContribution.format(grams: 1) == "1 g")
    }

    @Test func milligramScaleAmountsShowAsMilligrams() {
        #expect(NutrientContribution.format(grams: 0.31) == "310 mg")
        #expect(NutrientContribution.format(grams: 0.001) == "1 mg")
    }

    @Test func microgramScaleAmountsShowAsMicrograms() {
        #expect(NutrientContribution.format(grams: 0.000045) == "45 \u{00B5}g")
    }
}
