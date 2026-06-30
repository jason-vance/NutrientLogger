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
        expectGenerated("whole milk", "whole* AND milk*")
    }

    @Test func punctuationRemoved() {
        expectGenerated("whole, milk", "whole* AND milk*")
        expectGenerated("whole , milk", "whole* AND milk*")
    }

    @Test func extraSpacesCollapsed() {
        expectGenerated("whole    milk", "whole* AND milk*")
    }

    @Test func multipleWordsAllAnd() {
        expectGenerated("whole milk dessert bar", "whole* AND milk* AND dessert* AND bar*")
    }

    @Test func duplicateTokensDeduped() {
        expectGenerated("milk milk", "milk*")
    }

    @Test func nonStemmedTermBeforeStemmedTermIsValidFts5Syntax() {
        // Regression test: a bareword immediately followed by a parenthesized
        // OR group (e.g. "Five* (guys* OR guy*)") is invalid FTS5 syntax and
        // crashes the query. Joining with "AND" keeps it valid.
        expectGenerated("Five guys", "Five* AND (guys* OR guy*)")
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
        expectGenerated("chicken with rice", "chicken* AND rice*")
        expectGenerated("a cup of milk", "cup* AND milk*")
        expectGenerated("bread and butter", "bread* AND butter*")
    }

    @Test func allStopWordsPreserved() {
        expectGenerated("the", "the*")
        expectGenerated("a", "a*")
    }

    // MARK: - Abbreviations

    @Test func abbreviationExpansion() {
        expectGenerated("oj", "orange* AND juice*")
        expectGenerated("OJ", "orange* AND juice*")
        expectGenerated("pb toast", "peanut* AND butter* AND toast*")
        expectGenerated("evoo", "extra* AND virgin* AND olive* AND oil*")
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

    // MARK: - cleanProductName

    @Test func cleanProductName_removesBrand() {
        let result = FtsQueryGenerator.cleanProductName(
            "Kroger Whole Wheat Spaghetti",
            brand: "Kroger"
        )
        #expect(result == "Whole Wheat Spaghetti")
    }

    @Test func cleanProductName_removesBrandCaseInsensitive() {
        let result = FtsQueryGenerator.cleanProductName(
            "kroger Whole Wheat Spaghetti",
            brand: "Kroger"
        )
        #expect(result == "Whole Wheat Spaghetti")
    }

    @Test func cleanProductName_removesCommaSeparatedBrand() {
        let result = FtsQueryGenerator.cleanProductName(
            "Kroger Valley Spaghetti",
            brand: "Kroger,Valley"
        )
        #expect(result == "Spaghetti")
    }

    @Test func cleanProductName_removesSizePatterns() {
        #expect(FtsQueryGenerator.cleanProductName("Spaghetti 16oz") == "Spaghetti")
        #expect(FtsQueryGenerator.cleanProductName("Milk 500ml") == "Milk")
        #expect(FtsQueryGenerator.cleanProductName("Bread 1.5lb") == "Bread")
        #expect(FtsQueryGenerator.cleanProductName("Yogurt 12 fl oz") == "Yogurt")
    }

    @Test func cleanProductName_removesPackagingWords() {
        let result = FtsQueryGenerator.cleanProductName("Organic Frozen Spaghetti")
        #expect(result == "Spaghetti")
    }

    @Test func cleanProductName_fullCleanup() {
        let result = FtsQueryGenerator.cleanProductName(
            "Kroger Organic Whole Wheat Spaghetti 16oz",
            brand: "Kroger"
        )
        #expect(result == "Whole Wheat Spaghetti")
    }

    @Test func cleanProductName_noBrand() {
        let result = FtsQueryGenerator.cleanProductName("Whole Wheat Spaghetti")
        #expect(result == "Whole Wheat Spaghetti")
    }

    // MARK: - generateOrFrom

    @Test func orQuerySingleToken() {
        let result = FtsQueryGenerator.generateOrFrom("spaghetti")
        #expect(result == "spaghetti*")
    }

    @Test func orQueryMultipleTokens() {
        let result = FtsQueryGenerator.generateOrFrom("whole wheat spaghetti")
        #expect(result == "whole* OR wheat* OR spaghetti*")
    }

    @Test func orQueryWithStemming() {
        let result = FtsQueryGenerator.generateOrFrom("carrots")
        #expect(result == "(carrots* OR carrot*)")
    }

    @Test func orQueryEmpty() {
        let result = FtsQueryGenerator.generateOrFrom("")
        #expect(result == "")
    }

    // MARK: - Helpers

    private func expectGenerated(_ input: String, _ expectedOutput: String) {
        let result = FtsQueryGenerator.generateFrom(input)
        #expect(result == expectedOutput)
    }
}
