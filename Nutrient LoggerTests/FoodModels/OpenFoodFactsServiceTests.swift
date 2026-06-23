//
//  OpenFoodFactsServiceTests.swift
//  Nutrient LoggerTests
//

import Testing

struct OpenFoodFactsServiceTests_NormalizeServingSize {

    @Test func stripsTrailingGramWeight() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "2 tbsp (32g)", gramWeight: 32)
        #expect(name == "tbsp")
        #expect(grams == 16)
    }

    @Test func stripsTrailingGramWeightWithSpace() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "1 cup (240 g)", gramWeight: 240)
        #expect(name == "cup")
        #expect(grams == 240)
    }

    @Test func parsesLeadingNumberAndDivides() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "3 cookies", gramWeight: 90)
        #expect(name == "cookies")
        #expect(grams == 30)
    }

    @Test func parsesDecimalLeadingNumber() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "1.5 bars", gramWeight: 60)
        #expect(name == "bars")
        #expect(grams == 40)
    }

    @Test func keepsNameWhenNoLeadingNumber() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "cup", gramWeight: 240)
        #expect(name == "cup")
        #expect(grams == 240)
    }

    @Test func keepsFractionAsPartOfName() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "1/2 cup", gramWeight: 120)
        #expect(name == "1/2 cup")
        #expect(grams == 120)
    }

    @Test func handlesLeadingOneWithGramSuffix() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "1 bar (40g)", gramWeight: 40)
        #expect(name == "bar")
        #expect(grams == 40)
    }

    @Test func preservesBareGramMeasurement() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "30g", gramWeight: 30)
        #expect(name == "30g")
        #expect(grams == 30)
    }

    @Test func handlesExtraWhitespace() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "  2 tbsp  (32g)  ", gramWeight: 32)
        #expect(name == "tbsp")
        #expect(grams == 16)
    }

    @Test func handlesOnlyGramSuffix() {
        let (name, grams) = OpenFoodFactsService.normalizeServingSize(name: "(100g)", gramWeight: 100)
        #expect(name == "(100g)")
        #expect(grams == 100)
    }
}
