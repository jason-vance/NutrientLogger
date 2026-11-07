//
//  SearchQuerySplitterTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct SearchQuerySplitterTests {

    /// A pretend database: each known query and how many foods it finds.
    private func finder(_ counts: [String: Int]) -> SearchQuerySplitter.Finder {
        { query in counts[query].map { (query, $0) } }
    }

    private func parts(_ query: String, _ counts: [String: Int]) -> [String] {
        SearchQuerySplitter.parts(of: query, find: finder(counts)).map(\.name)
    }

    @Test func splitsAtConnectorWords() {
        let counts = ["bagel": 40, "cream cheese": 12, "cream": 90, "cheese": 800]
        #expect(parts("bagel with cream cheese", counts) == ["Bagel", "Cream cheese"])
        #expect(parts("bagel & cream cheese", counts) == ["Bagel", "Cream cheese"])
        #expect(parts("avocado on toast", ["avocado": 5, "toast": 30]) == ["Avocado", "Toast"])
    }

    @Test func splitsTwoFoodsTypedTogetherWhereBothHalvesFindTheMost() {
        let counts = ["peanut": 60, "butter": 200, "toast": 30, "peanut butter": 25, "butter toast": 2]
        #expect(parts("peanut butter toast", counts) == ["Peanut butter", "Toast"])
    }

    @Test func dropsWordsNoFoodHas() {
        #expect(parts("starbucks latte", ["latte": 20]) == ["Latte"])
    }

    @Test func neverSearchesADescribingWordAlone() {
        let counts = ["roasted": 300, "vegetables": 700]
        #expect(parts("roasted vegetables", counts) == ["Vegetables"])
        #expect(parts("loaded baked potato", ["loaded": 3, "baked": 900, "potato": 400, "baked potato": 50]) == ["Baked potato"])
    }

    @Test func turnsADescribingWordIntoItsFood() {
        let counts = ["butter": 80, "toast": 30]
        #expect(parts("buttered toast", counts) == ["Butter", "Toast"])
    }

    @Test func keepsTheCorrectedQueryForSearching() {
        let find: SearchQuerySplitter.Finder = { query in
            switch query {
            case "coke": return ("soft drink cola", 9)
            case "fries": return ("fries", 40)
            default: return nil
            }
        }
        let result = SearchQuerySplitter.parts(of: "coke and fries", find: find)
        #expect(result == [
            SearchQueryPart(name: "Coke", query: "soft drink cola"),
            SearchQueryPart(name: "Fries", query: "fries"),
        ])
    }

    @Test func nothingWhenNoPartFindsAnything() {
        #expect(parts("kombucha", [:]).isEmpty)
        #expect(parts("zzz qqq", [:]).isEmpty)
    }

    @Test func ignoresAmounts() {
        #expect(parts("2 eggs and 1 slice of toast", ["eggs": 300, "toast": 30]) == ["Eggs", "Toast"])
    }
}
