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

    @Test func drinksAndOuncesStartAtAUsualServing() {
        let flOz = Portion(name: "fl oz", amount: 1, gramWeight: 31)
        let ozCooked = Portion(name: "oz, cooked", amount: 1, gramWeight: 28.35)
        let oz = Portion(name: "oz", amount: 1, gramWeight: 28.35)
        let fourOz = Portion(name: "oz", amount: 4, gramWeight: 28.25)
        #expect(LogPortionDefaults.defaultAmount(for: flOz) == 8)
        #expect(LogPortionDefaults.defaultAmount(for: ozCooked) == 4)
        #expect(LogPortionDefaults.defaultAmount(for: oz) == 1)
        #expect(LogPortionDefaults.defaultAmount(for: fourOz) == 4)
        #expect(LogPortionDefaults.amountAfterSwitching(from: cup, to: flOz, currentAmount: 1) == 8)
        #expect(LogPortionDefaults.quickAmounts(for: flOz) == [4, 8, 12, 16, 20])
    }

    // MARK: - Portion order (names and weights from the bundled USDA data)

    @Test func countedFoodsStartWithOneOfTheThing() {
        expectFirst("egg", food: "Egg, whole, raw", [("cup", 245), ("egg", 50)])
        expectFirst("banana", food: "Banana, raw", [
            ("linear inch", 15), ("cup, mashed", 225), ("cup", 150), ("banana", 126), ("slice", 6),
        ])
        expectFirst("fruit", food: "Orange, raw", [("section/slice", 15), ("cup", 180), ("fruit", 154)])
    }

    @Test func mediumSizeComesFirst() {
        expectFirst("medium", food: "Apple, raw", [
            ("single serving package", 34), ("cup", 125), ("extra large", 295), ("large", 242), ("medium", 200),
        ])
    }

    @Test func breadStartsWithARegularSlice() {
        expectFirst("medium or regular slice", food: "Bread, white, toasted", [
            ("cup", 40), ("cubic inch", 3.9), ("large or thick slice", 39),
            ("slice, crust not eaten", 12), ("medium or regular slice", 25),
        ])
    }

    @Test func drinksStartWithACupOrCanNotACafeSize() {
        expectFirst("cup (8 fl oz)", food: "Coffee, brewed", [
            ("large pot (60 FO, 12 servings)", 1800), ("small", 360), ("cup (8 fl oz)", 240), ("fl oz", 30),
        ])
        expectFirst("can (12 fl oz)", food: "Soft drink, NFS", [
            ("large drink", 744), ("small drink", 372), ("fl oz (with ice)", 23), ("can (12 fl oz)", 372),
        ])
        expectFirst("fl oz (NFS)", food: "Orange juice, 100%, NFS", [
            ("individual school container", 124), ("juice box/pouch (6.75 fl oz)", 209),
            ("fl oz (with ice)", 23), ("fl oz (NFS)", 31),
        ])
    }

    @Test func spreadsAndOilsStartWithASpoon() {
        expectFirst("tablespoon", food: "Olive oil", [("cup", 224), ("tablespoon", 14)])
        expectFirst("pat", food: "Butter, NFS", [("cup", 224), ("pat", 5), ("tablespoon", 14)])
        // A cup of lentils is a normal amount, so the spoon doesn't take over.
        expectFirst("cup", food: "Lentils, raw", [("tablespoon", 12), ("cup", 192)])
    }

    @Test func ouncesBeatACupForNutsAndMeat() {
        expectFirst("oz", food: "Almonds, NFS", [("cup", 141), ("oz", 28.35)])
        expectFirst("oz, boneless, raw", food: "Salmon, raw", [("cup, NFS", 166), ("oz, boneless, raw", 28.35)])
    }

    @Test func tinyPiecesLoseToACup() {
        expectFirst("cup", food: "Grapes, raw", [("grape", 7), ("cup", 150)])
        expectFirst("cup, whole", food: "Strawberries, raw", [("extra large (1-5/8\" dia)", 27), ("cup, whole", 144)])
        expectFirst("cup", food: "Mushrooms, raw", [("piece/slice", 6), ("cup", 70)])
        // Garlic is the exception: people log cloves.
        expectFirst("clove", food: "Garlic, raw", [("cup", 136), ("clove", 3)])
    }

    @Test func oddPortionsGoLastAndGramsStayAtTheEnd() {
        let portions = [
            Portion(name: "surface inch", amount: 1, gramWeight: 1.9),
            Portion(name: "Guideline amount per cup of hot cereal", amount: 1, gramWeight: 61),
            grams,
            Portion(name: "medium pancake", amount: 1, gramWeight: 50),
        ]
        let ordered = LogPortionDefaults.ordered(portions, foodName: "Pancakes, NFS").map(\.name)
        #expect(ordered.first == "medium pancake")
        #expect(ordered.last == "g")
    }

    private func expectFirst(_ expected: String, food: String, _ portions: [(String, Double)]) {
        let list = portions.map { Portion(name: $0.0, amount: 1, gramWeight: $0.1) } + [grams]
        #expect(LogPortionDefaults.ordered(list, foodName: food).first?.name == expected)
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
