//
//  SearchSpellCorrectorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/4/26.
//

import Testing

struct SearchSpellCorrectorTests {

    private let corrector = SearchSpellCorrector(foodNames: [
        "Broccoli, raw",
        "Broth, beef",
        "Chicken, broilers, breast, raw",
        "Banana, raw",
        "Bananas, dehydrated, or banana powder",
        "Avocado, raw",
        "Spaghetti, cooked",
        "Beef, ground, raw",
        "Beef, chuck, raw",
        "Beef liver, fried",
        "Lettuce, leaf, raw",
        "Yogurt, plain, whole milk",
        "Pineapple, raw",
        "Coffee, espresso",
        "Jalapeño peppers, raw",
    ])

    @Test func correctsSingleTypos() {
        #expect(corrector.correct("brocoli") == "broccoli")
        #expect(corrector.correct("bananna") == "banana")
        #expect(corrector.correct("avacado") == "avocado")
        #expect(corrector.correct("spagetti") == "spaghetti")
        #expect(corrector.correct("yoghurt") == "yogurt")
        #expect(corrector.correct("expresso") == "espresso")
        #expect(corrector.correct("pinapple") == "pineapple")
    }

    @Test func correctsSwappedLetters() {
        #expect(corrector.correct("chikcen") == "chicken")
    }

    @Test func isCaseInsensitive() {
        #expect(corrector.correct("Brocoli") == "broccoli")
    }

    @Test func leavesWordsBeingTypedAlone() {
        #expect(corrector.correct("chick") == nil)
        #expect(corrector.correct("broc") == nil)
    }

    @Test func leavesCorrectWordsAlone() {
        #expect(corrector.correct("banana") == nil)
    }

    @Test func leavesShortWordsAndNumbersAlone() {
        #expect(corrector.correct("bef") == nil)
        #expect(corrector.correct("12345") == nil)
    }

    @Test func picksTheMoreCommonWordOnATie() {
        // "beaf" is one letter off both "beef" (4 foods) and "leaf" (1 food).
        #expect(corrector.correct("beaf") == "beef")
    }

    @Test func returnsNilWhenNothingIsClose() {
        #expect(corrector.correct("xyzzy") == nil)
    }

    @Test func matchesAccentedWords() {
        #expect(SearchSpellCorrector.words(in: "Jalapeño peppers, raw") == ["jalapeno", "peppers", "raw"])
        #expect(corrector.correct("jalepeno") == "jalapeno")
    }

    @Test func editDistance() {
        #expect(SearchSpellCorrector.editDistance("kitten", "kitten", max: 2) == 0)
        #expect(SearchSpellCorrector.editDistance("kitten", "sitten", max: 2) == 1)
        #expect(SearchSpellCorrector.editDistance("kitten", "kiten", max: 2) == 1)
        #expect(SearchSpellCorrector.editDistance("kitten", "iktten", max: 2) == 1)
        #expect(SearchSpellCorrector.editDistance("kitten", "sitting", max: 3) == 3)
        #expect(SearchSpellCorrector.editDistance("kitten", "sitting", max: 1) > 1)
    }
}
