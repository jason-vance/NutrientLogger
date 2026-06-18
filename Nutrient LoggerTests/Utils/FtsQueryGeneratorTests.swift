//
//  FtsQueryGeneratorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Testing

struct FtsQueryGeneratorTests {

    // MARK: - generateFrom (AND logic, stemming, stop words, abbreviations)

    @Test func singleWord() {
        expectGenerated("milk", "milk*")
    }

    @Test func multipleWordsUseAndLogic() {
        expectGenerated("whole milk", "whole* milk*")
    }

    @Test func punctuationRemoved() {
        expectGenerated("whole, milk", "whole* milk*")
        expectGenerated("whole , milk", "whole* milk*")
    }

    @Test func extraSpacesCollapsed() {
        expectGenerated("whole    milk", "whole* milk*")
    }

    @Test func multipleWordsAllAnd() {
        expectGenerated("whole milk dessert bar", "whole* milk* dessert* bar*")
    }

    @Test func duplicateTokensDeduped() {
        expectGenerated("milk milk", "milk*")
    }

    // MARK: - Stemming

    @Test func stemSuffix_s() {
        expectGenerated("bagels", "(bagels* OR bagel*)")
        expectGenerated("BAGELS", "(BAGELS* OR BAGEL*)")
        expectGenerated("carrots", "(carrots* OR carrot*)")
    }

    @Test func stemSuffix_es() {
        expectGenerated("dresses", "(dresses* OR dress*)")
        expectGenerated("DRESSES", "(DRESSES* OR DRESS*)")
        expectGenerated("dishes", "(dishes* OR dish*)")
        expectGenerated("peaches", "(peaches* OR peach*)")
    }

    @Test func stemSuffix_ies() {
        expectGenerated("berries", "(berries* OR berry*)")
        expectGenerated("cherries", "(cherries* OR cherry*)")
    }

    @Test func stemSuffix_ves() {
        expectGenerated("loaves", "(loaves* OR loaf*)")
    }

    @Test func stemSuffix_oes() {
        expectGenerated("tomatoes", "(tomatoes* OR tomato*)")
        expectGenerated("potatoes", "(potatoes* OR potato*)")
    }

    @Test func stemSuffix_ses() {
        expectGenerated("cheeses", "(cheeses* OR cheese*)")
    }

    @Test func doNotStemProtectedWords() {
        expectGenerated("cheese", "cheese*")
        expectGenerated("rice", "rice*")
        expectGenerated("juice", "juice*")
        expectGenerated("sauce", "sauce*")
        expectGenerated("mousse", "mousse*")
        expectGenerated("hummus", "hummus*")
    }

    @Test func doNotStemSingleS_ss() {
        expectGenerated("grass", "grass*")
        expectGenerated("bass", "bass*")
    }

    @Test func shortWordsNotStemmed() {
        expectGenerated("as", "as*")
        expectGenerated("us", "us*")
    }

    // MARK: - Stop words

    @Test func stopWordsRemoved() {
        expectGenerated("chicken with rice", "chicken* rice*")
        expectGenerated("a cup of milk", "cup* milk*")
        expectGenerated("bread and butter", "bread* butter*")
    }

    @Test func allStopWordsPreserved() {
        expectGenerated("the", "the*")
        expectGenerated("a", "a*")
    }

    // MARK: - Abbreviations

    @Test func abbreviationExpansion() {
        expectGenerated("oj", "orange* juice*")
        expectGenerated("OJ", "orange* juice*")
        expectGenerated("pb toast", "peanut* butter* toast*")
        expectGenerated("evoo", "extra* virgin* olive* oil*")
    }

    // MARK: - generateExactFrom

    @Test func exactQueryNoWildcards() {
        let result = FtsQueryGenerator.generateExactFrom("whole milk")
        #expect(result == "whole milk")
    }

    @Test func exactQueryStopWordsRemoved() {
        let result = FtsQueryGenerator.generateExactFrom("chicken with rice")
        #expect(result == "chicken rice")
    }

    @Test func exactQueryAbbreviationsExpanded() {
        let result = FtsQueryGenerator.generateExactFrom("oj")
        #expect(result == "orange juice")
    }

    // MARK: - generatePhraseFrom

    @Test func phraseQueryMultipleWords() {
        let result = FtsQueryGenerator.generatePhraseFrom("chicken breast")
        #expect(result == "\"chicken breast\"")
    }

    @Test func phraseQuerySingleWordReturnsNil() {
        let result = FtsQueryGenerator.generatePhraseFrom("milk")
        #expect(result == nil)
    }

    @Test func phraseQueryStopWordsRemoved() {
        let result = FtsQueryGenerator.generatePhraseFrom("chicken with breast")
        #expect(result == "\"chicken breast\"")
    }

    // MARK: - Helpers

    private func expectGenerated(_ input: String, _ expectedOutput: String) {
        let result = FtsQueryGenerator.generateFrom(input)
        #expect(result == expectedOutput)
    }
}
