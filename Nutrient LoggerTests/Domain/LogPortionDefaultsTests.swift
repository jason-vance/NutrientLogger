//
//  LogPortionDefaultsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/4/26.
//

import Testing

struct LogPortionDefaultsTests {

    private let cup = Portion(name: "1 cup", amount: 1, gramWeight: 240)
    private let large = Portion(name: "1 large", amount: 1, gramWeight: 50)
    private let grams = Portion.defaultPortion

    @Test func firstPortionAndOneWhenNeverLogged() {
        let selection = LogPortionDefaults.initialSelection(portions: [large, cup], lastLogged: nil)
        #expect(selection.selected == large)
        #expect(selection.amount == 1)
    }

    @Test func gramPortionStartsAtOneHundred() {
        let selection = LogPortionDefaults.initialSelection(portions: [grams], lastLogged: nil)
        #expect(selection.amount == 100)
    }

    @Test func reusesLastTimesPortionAndAmount() {
        let last = LogPortionDefaults.LastLogged(portionName: "1 cup", gramWeight: 240, amount: 1.5)
        let selection = LogPortionDefaults.initialSelection(portions: [large, cup], lastLogged: last)
        #expect(selection.selected == cup)
        #expect(selection.amount == 1.5)
        #expect(selection.portions == [large, cup])
    }

    @Test func restoresLastPortionWhenNoLongerListed() {
        let last = LogPortionDefaults.LastLogged(portionName: "1 slice", gramWeight: 28, amount: 2)
        let selection = LogPortionDefaults.initialSelection(portions: [cup], lastLogged: last)
        #expect(selection.selected?.name == "1 slice")
        #expect(selection.portions.count == 2)
        #expect(selection.amount == 2)
    }

    @Test func switchingBetweenGramsAndCountedPortionsResetsAmount() {
        #expect(LogPortionDefaults.amountAfterSwitching(from: cup, to: grams, currentAmount: 2) == 100)
        #expect(LogPortionDefaults.amountAfterSwitching(from: grams, to: cup, currentAmount: 150) == 1)
        #expect(LogPortionDefaults.amountAfterSwitching(from: cup, to: large, currentAmount: 2) == 2)
    }

    @Test func quickAmountsFitThePortion() {
        #expect(LogPortionDefaults.quickAmounts(for: cup) == [0.5, 1, 1.5, 2, 3])
        #expect(LogPortionDefaults.quickAmounts(for: grams) == [50, 100, 150, 200])
        #expect(LogPortionDefaults.quickAmounts(for: nil).isEmpty)
    }

    @Test func labels() {
        #expect(LogPortionDefaults.label(for: 0.5) == "½")
        #expect(LogPortionDefaults.label(for: 1) == "1")
        #expect(LogPortionDefaults.label(for: 1.5) == "1½")
        #expect(LogPortionDefaults.label(for: 150) == "150")
    }

    @Test func parsesTypedAmounts() {
        #expect(LogPortionDefaults.parseAmount("2") == 2)
        #expect(LogPortionDefaults.parseAmount("1.5") == 1.5)
        #expect(LogPortionDefaults.parseAmount("1,5") == 1.5)
        #expect(LogPortionDefaults.parseAmount(" 3 ") == 3)
        #expect(LogPortionDefaults.parseAmount("") == nil)
        #expect(LogPortionDefaults.parseAmount("0") == nil)
        #expect(LogPortionDefaults.parseAmount("1.") == 1)
    }

    @Test func shortensUsdaMeasurementDetails() {
        #expect(LogPortionDefaults.shortName("1 slice (6-1/2\" x 2-3/8\" x 3/8\")") == "1 slice")
        #expect(LogPortionDefaults.shortName("1 cup (8 fl oz)") == "1 cup")
        #expect(LogPortionDefaults.shortName("1 cup, chopped") == "1 cup, chopped")
        #expect(LogPortionDefaults.shortName("1 large (whole)") == "1 large (whole)")
    }

    @Test func keepsFullNamesWhenShortOnesWouldClash() {
        let portions = [
            Portion(name: "1 slice (small)", amount: 1, gramWeight: 20),
            Portion(name: "1 cup (8 fl oz)", amount: 1, gramWeight: 240),
            Portion(name: "1 cup (4 oz)", amount: 1, gramWeight: 113),
            Portion(name: "1 oz", amount: 1, gramWeight: 28),
        ]
        #expect(LogPortionDefaults.pillLabels(for: portions) == [
            "1 slice (small)", "1 cup (8 fl oz)", "1 cup (4 oz)", "1 oz",
        ])
    }

    @Test func featuresAFewPortionsWhenThereAreMany() {
        let names = ["extra large", "large", "small", "medium", "bottle", "can", "fl oz"]
        let portions = names.enumerated().map { Portion(name: $1, amount: 1, gramWeight: Double(100 + $0)) }
            + [Portion(name: "g", amount: 1, gramWeight: 1)]
        let can = portions[5]

        // The picked portion and grams always make the cut, then the first ones in the list.
        #expect(LogPortionDefaults.featuredPortionIndices(portions, anchor: can) == [0, 1, 5, 7])
        #expect(LogPortionDefaults.featuredPortionIndices(portions, anchor: nil) == [0, 1, 2, 7])
    }

    @Test func showsShortPortionListsInFull() {
        let portions = (0..<5).map { Portion(name: "p\($0)", amount: 1, gramWeight: Double(10 + $0)) }
        #expect(LogPortionDefaults.featuredPortionIndices(portions, anchor: portions[4]) == [0, 1, 2, 3, 4])
    }

    @Test func summarizesWhatWillBeLogged() {
        #expect(LogPortionDefaults.summary(amount: 2, portionName: "1 slice (6-1/2\" x 2-3/8\")") == "2 × 1 slice")
        #expect(LogPortionDefaults.summary(amount: 150, portionName: "g") == "150 g")
        #expect(LogPortionDefaults.summary(amount: 1.5, portionName: "cup") == "1½ cup")
    }

    @Test func recognizesLastTimesChoice() {
        let last = LogPortionDefaults.LastLogged(portionName: "1 cup", gramWeight: 240, amount: 2)
        let cup = Portion(name: "1 cup", amount: 2, gramWeight: 240)
        #expect(LogPortionDefaults.matchesLastTime(portion: cup, amount: 2, lastLogged: last))
        #expect(!LogPortionDefaults.matchesLastTime(portion: cup, amount: 1, lastLogged: last))
        #expect(!LogPortionDefaults.matchesLastTime(portion: .defaultPortion, amount: 2, lastLogged: last))
        #expect(!LogPortionDefaults.matchesLastTime(portion: cup, amount: 2, lastLogged: nil))
    }
}
