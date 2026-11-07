//
//  GapFoodsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct GapFoodsTests {

    private let liver = GapFoods.Food(fdcId: 1, name: "beef liver", serving: "3 oz", grams: 85, kind: .organ)
    private let spinach = GapFoods.Food(fdcId: 2, name: "cooked spinach", serving: "1 cup", grams: 180, kind: .vegetable)
    private let lentils = GapFoods.Food(fdcId: 3, name: "lentils", serving: "1 cup", grams: 198, kind: .legume)
    private let cheese = GapFoods.Food(fdcId: 4, name: "cheddar", serving: "1 oz", grams: 28, kind: .dairy)
    private let seeds = GapFoods.Food(fdcId: 5, name: "pumpkin seeds", serving: "1 oz", grams: 28, kind: .seed)

    private var foods: [GapFoods.Food] { [liver, spinach, lentils, cheese, seeds] }

    private func names(_ amounts: [Int: Double], goal: Double = 100, upperLimit: Double? = nil, diet: NutritionDietPreset?) -> [String] {
        GapFoods.suggestions(amountsPerServing: amounts, goal: goal, upperLimit: upperLimit, diet: diet, foods: foods)
            .map(\.food.name)
    }

    @Test func ranksByShareOfTheGoal() {
        let amounts = [1: 60.0, 2: 40, 3: 80, 4: 20, 5: 50]
        #expect(names(amounts, diet: .balanced) == ["lentils", "beef liver", "pumpkin seeds"])
    }

    @Test func fitsTheDiet() {
        let amounts = [1: 60.0, 2: 40, 3: 80, 4: 20, 5: 50]
        #expect(names(amounts, diet: .carnivore) == ["beef liver", "cheddar"])
        #expect(names(amounts, diet: .plantBased) == ["lentils", "pumpkin seeds", "cooked spinach"])
        #expect(names(amounts, diet: .ketoLowCarb) == ["beef liver", "pumpkin seeds", "cooked spinach"])
        #expect(names(amounts, diet: .paleo) == ["beef liver", "pumpkin seeds", "cooked spinach"])
    }

    @Test func skipsFoodsThatBarelyHelp() {
        #expect(names([1: 9, 2: 10], diet: .balanced) == ["cooked spinach"])
    }

    @Test func skipsAServingOverTheUpperLimit() {
        #expect(names([1: 900, 2: 40], upperLimit: 300, diet: .balanced) == ["cooked spinach"])
    }

    @Test func readsAsASentence() {
        let suggestions = GapFoods.suggestions(amountsPerServing: [1: 60, 2: 40, 5: 50], goal: 100, diet: nil, foods: foods)
        #expect(GapFoods.sentence(suggestions) == "beef liver (3 oz), pumpkin seeds (1 oz) or cooked spinach (1 cup)")
        #expect(GapFoods.sentence(Array(suggestions.prefix(1))) == "beef liver (3 oz)")
        #expect(GapFoods.sentence([]) == nil)
    }

    @Test func everyFoodIsListedOnce() {
        let ids = GapFoods.pool.map(\.fdcId)
        #expect(Set(ids).count == ids.count)
    }
}
