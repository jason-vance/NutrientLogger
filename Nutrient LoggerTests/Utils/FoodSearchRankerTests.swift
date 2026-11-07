//
//  FoodSearchRankerTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/4/26.
//

import Testing

struct FoodSearchRankerTests {

    @Test func plainFoodBeatsProcessedForm() {
        expectFirst("banana", "Banana, raw", among: [
            "Bananas, dehydrated, or banana powder",
            "SILK Banana-Strawberry soy yogurt",
            "Banana, raw",
        ])
    }

    @Test func plainEggBeatsDriedEggAndEggplant() {
        expectFirst("egg", "Egg, whole, raw, fresh", among: [
            "Egg, whole, dried",
            "Eggplant, raw",
            "Egg, whole, raw, fresh",
        ])
    }

    @Test func pluralQueryMatchesSingularName() {
        expectFirst("eggs", "Egg, whole, raw, fresh", among: [
            "Eggs, scrambled, frozen mixture",
            "Scrambled eggs with jerked beef, Puerto Rican style",
            "Egg, whole, raw, fresh",
        ])
    }

    @Test func singularQueryMatchesIesPlural() {
        expectFirst("strawberry", "Strawberries, raw", among: [
            "Strawberry milk, NFS",
            "Strawberry-flavor beverage mix, powder",
            "Strawberries, raw",
        ])
    }

    @Test func genericEntryBeatsSpecificOnes() {
        expectFirst("milk", "Milk, NFS", among: [
            "Milk dessert, frozen, milk-fat free, chocolate",
            "Milk, sheep, fluid",
            "Milk, NFS",
        ])
    }

    @Test func longerWordWithSamePrefixDoesNotCount() {
        expectFirst("butter", "Butter, NFS", among: [
            "Butterbur, (fuki), raw",
            "Butter, NFS",
        ])
    }

    @Test func brandedEntryRanksBelowGeneric() {
        expectFirst("coffee", "Coffee, brewed", among: [
            "SILK Coffee, soymilk",
            "Coffee, brewed",
        ])
    }

    @Test func wordPositionStillComesFirst() {
        expectFirst("chicken", "Chicken, broilers or fryers, breast, raw", among: [
            "Soup, chicken noodle, canned",
            "Chicken, broilers or fryers, breast, raw",
        ])
    }

    @Test func typedQualifierFindsThatForm() {
        let ranked = rank("dried apricots", [
            "Apricots, raw",
            "Apricots, dried, sulfured, uncooked",
        ])
        #expect(ranked.first == "Apricots, dried, sulfured, uncooked")
    }

    @Test func duplicateNamesShownOnce() {
        let foods = [
            FdcSearchableFood(fdcId: 1, description: "Strawberries, raw", rank: 0),
            FdcSearchableFood(fdcId: 2, description: "Strawberries, raw", rank: 0),
        ]
        let ranked = FoodSearchRanker.rank(foods, tokens: ["strawberries"])
        #expect(ranked.map(\.fdcId) == [1])
    }

    @Test func tiesKeepOriginalOrder() {
        let red = FdcSearchableFood(fdcId: 1, description: "Kale, red", rank: 0)
        let wet = FdcSearchableFood(fdcId: 2, description: "Kale, wet", rank: 0)
        #expect(FoodSearchRanker.rank([red, wet], tokens: ["kale"]).map(\.fdcId) == [1, 2])
        #expect(FoodSearchRanker.rank([wet, red], tokens: ["kale"]).map(\.fdcId) == [2, 1])
    }

    @Test func plainFoodBeatsDishThatContainsIt() {
        expectFirst("brown rice", "Rice, brown, cooked, no added fat", among: [
            "Beans and brown rice",
            "Black beans and brown rice",
            "Rice, brown, cooked, no added fat",
        ])
        expectFirst("cheddar cheese", "Cheese, Cheddar", among: [
            "Cheddar cheese soup, home recipe, canned or ready-to-serve",
            "Cheese, Cheddar",
        ])
    }

    @Test func wholeWordBeatsLongerWordWithSamePrefix() {
        expectFirst("fried egg", "Egg, whole, fried with oil", among: [
            "Fried eggplant",
            "Egg, whole, fried with oil",
        ])
        expectFirst("pita", "Bread, pita", among: [
            "Pitanga, (surinam-cherry), raw",
            "Bread, pita",
        ])
    }

    @Test func partialWordsStillMatchWhileTyping() {
        expectFirst("straw", "Strawberries, raw", among: [
            "Strawberries, raw",
            "Strawberry milk, NFS",
        ])
    }

    @Test func stopWordsDoNotMakeANameADish() {
        expectFirst("pepperoni pizza", "Pizza with pepperoni, stuffed crust", among: [
            "Pepperoni pizza rolls",
            "Pizza with pepperoni, stuffed crust",
        ])
    }

    @Test func wholeWheatIsNotTheEverydayForm() {
        expectFirst("pizza", "Pizza, cheese, stuffed crust", among: [
            "Pizza, cheese, whole wheat thin crust",
            "Pizza, cheese, stuffed crust",
        ])
    }

    @Test func iesPluralFindsIeSingular() {
        expectFirst("cookies", "Cookie, NFS", among: [
            "Cookies, peanut butter sandwich, regular",
            "Cookie, NFS",
        ])
    }

    // MARK: - Helpers

    private func rank(_ query: String, _ descriptions: [String]) -> [String] {
        let foods = descriptions.enumerated().map {
            FdcSearchableFood(fdcId: $0.offset, description: $0.element, rank: 0)
        }
        return FoodSearchRanker
            .rank(foods, tokens: FtsQueryGenerator.tokenize(query))
            .map(\.description)
    }

    private func expectFirst(_ query: String, _ expected: String, among descriptions: [String]) {
        #expect(rank(query, descriptions).first == expected)
    }
}
