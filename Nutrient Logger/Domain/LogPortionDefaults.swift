//
//  LogPortionDefaults.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import Foundation

/// Picks sensible starting values on the log-food screen so most foods need no edits:
/// the portion and amount used last time, and one-tap amounts that fit the portion.
enum LogPortionDefaults {

    /// What was logged last time for this food.
    struct LastLogged: Equatable {
        let portionName: String
        let gramWeight: Double
        let amount: Double
    }

    struct Selection: Equatable {
        let portions: [Portion]
        let selected: Portion?
        let amount: Double
    }

    /// Reuses last time's portion and amount when there is one. If that portion is no longer in
    /// the list, it's added at the front so it can still be picked.
    static func initialSelection(portions: [Portion], lastLogged: LastLogged?) -> Selection {
        guard let last = lastLogged, last.amount > 0 else {
            let first = portions.first
            return Selection(portions: portions, selected: first, amount: first.map(defaultAmount(for:)) ?? 1)
        }

        if let match = portions.first(where: { isSamePortion($0, name: last.portionName, gramWeight: last.gramWeight) }) {
            return Selection(portions: portions, selected: match, amount: last.amount)
        }

        let restored = Portion(name: last.portionName, amount: 1, gramWeight: last.gramWeight)
        return Selection(portions: [restored] + portions, selected: restored, amount: last.amount)
    }

    static func isSamePortion(_ portion: Portion, name: String, gramWeight: Double) -> Bool {
        portion.name == name && abs(portion.gramWeight - gramWeight) < 0.001
    }

    static func isSamePortion(_ a: Portion?, _ b: Portion) -> Bool {
        guard let a else { return false }
        return isSamePortion(a, name: b.name, gramWeight: b.gramWeight)
    }

    /// A gram-based portion ("g") is counted in grams, so "1" means one gram.
    static func isGramPortion(_ portion: Portion) -> Bool {
        abs(portion.gramWeight - 1) < 0.001
    }

    /// How a portion is counted, which decides sensible amounts: nobody logs 1 g or 1 fl oz of milk.
    enum AmountUnit: Equatable {
        case grams, fluidOunces, ounces, count
    }

    static func amountUnit(for portion: Portion) -> AmountUnit {
        if isGramPortion(portion) { return .grams }
        let name = portion.name.lowercased()
        if name.hasPrefix("fl oz") { return .fluidOunces }
        if name == "oz" || name.hasPrefix("oz,") || name.hasPrefix("oz ") { return .ounces }
        return .count
    }

    static func defaultAmount(for portion: Portion) -> Double {
        switch amountUnit(for: portion) {
        case .grams: return 100
        case .fluidOunces: return 8
        case .ounces:
            // USDA's own amount when it gives one ("4 oz"). Otherwise a serving of meat or fish
            // ("oz, cooked", "oz, boneless, raw") is about 4 oz, and anything else (nuts, cheese) 1.
            if portion.amount > 1 { return portion.amount }
            let isMeatCut = !Set(words(in: portion.name)).isDisjoint(with: ["cooked", "raw", "boneless", "bone"])
            return isMeatCut ? 4 : 1
        case .count: return 1
        }
    }

    static func quickAmounts(for portion: Portion?) -> [Double] {
        guard let portion else { return [] }
        switch amountUnit(for: portion) {
        case .grams: return [50, 100, 150, 200]
        case .fluidOunces: return [4, 8, 12, 16, 20]
        case .ounces: return [1, 2, 3, 4, 6, 8]
        case .count: return [0.5, 1, 1.5, 2, 3]
        }
    }

    /// Switching between kinds of unit would otherwise turn "1 cup" into "1 g" or "100 g" into
    /// "100 cups", so the amount resets to that unit's usual one.
    static func amountAfterSwitching(from old: Portion?, to new: Portion, currentAmount: Double) -> Double {
        guard let old, amountUnit(for: old) != amountUnit(for: new) else { return currentAmount }
        return defaultAmount(for: new)
    }

    // MARK: - Portion order

    /// USDA lists portions in no useful order, so a first log of an egg or a coffee could default
    /// to "1 cup" or "1 large pot". This puts the portion people usually log first:
    /// 1. one of the thing: its own unit ("egg", "banana", "medium bagel") or a whole item
    ///    ("fruit", "medium" apple), if it's a realistic single serving
    /// 2. a common serving unit ("medium or regular slice", "can", "glass", "clove", "pat"), and
    ///    for spreads, oils and sauces a tablespoon
    /// 3. ounces or a plain cup, ounces first ("oz, cooked" for meat, "oz" for nuts)
    /// 4. other measures ("cup, diced", "fl oz", "tbsp")
    /// 5. odd ones ("surface inch", "Guideline amount…", "oz, dry, yields", "head")
    /// Medium sizes come before large and small, and plain names before qualified ones.
    /// Grams stay at the end.
    static func ordered(_ portions: [Portion], foodName: String) -> [Portion] {
        let context = OrderContext(portions: portions, foodName: foodName)
        let counted = portions.enumerated()
            .filter { !isGramPortion($0.element) }
            .map { index, portion in (portion, orderKey(portion, context: context) + [index]) }
            .sorted { $0.1.lexicographicallyPrecedes($1.1) }
            .map(\.0)
        return counted + portions.filter(isGramPortion)
    }

    private struct OrderContext {
        let foodWords: Set<String>
        let isDrink: Bool
        let hasPlainCup: Bool
        /// Spreads, oils and sauces: a spoon portion, and a cup that's either missing or heavy
        /// (a cup of oil or ketchup is 200+ g, nobody's serving).
        let isSpooned: Bool

        init(portions: [Portion], foodName: String) {
            foodWords = Set(LogPortionDefaults.words(in: foodName).map(LogPortionDefaults.singular))
            isDrink = portions.contains { amountUnit(for: $0) == .fluidOunces }
            let plainCups = portions.filter { LogPortionDefaults.isPlainCup($0) }
            hasPlainCup = !plainCups.isEmpty
            let hasSpoon = portions.contains { LogPortionDefaults.isSpoon($0) }
            isSpooned = hasSpoon && (plainCups.isEmpty || plainCups.contains { $0.gramWeight >= 200 })
        }
    }

    private static let sizeRanks: [String: Int] = [
        "medium": 0, "regular": 0,
        "large": 2, "small": 3, "extra": 4,
        "miniature": 5, "mini": 5, "bite": 5, "thick": 2, "thin": 3, "very": 3,
    ]
    private static let fillerWords: Set<String> = ["or", "any", "size", "nfs", "cooked", "boneless"]
    private static let wholeItemWords: Set<String> = ["fruit", "whole", "each", "item"]
    private static let servingWords: Set<String> = [
        "slice", "patty", "link", "clove", "cloves", "can", "glass", "piece", "pat",
    ]
    private static let spoonWords: Set<String> = ["tbsp", "tablespoon", "tsp", "teaspoon"]
    /// Containers and drink sizes aren't one of the thing: "juice box", "small drink".
    private static let notAnItemWords: Set<String> = [
        "box", "pouch", "bottle", "container", "package", "bag", "carton", "jar", "packet",
        "drink", "drinks",
    ]
    private static let preparedCupWords: Set<String> = [
        "mashed", "pureed", "puree", "diced", "crumbled", "pieces", "grated", "ice",
        "flaked", "shredded", "cubed", "melted", "crushed",
    ]
    /// Words that don't make a portion name more specific, so "slice" and "medium or regular
    /// slice" both count as plain while "cracker-size slice" doesn't.
    private static let plainNameWords: Set<String> = fillerWords.union(wholeItemWords).union(servingWords)
        .union(sizeRanks.keys).union(["cup", "oz", "fl"])
    private static let oddWords: Set<String> = [
        "inch", "guideline", "yield", "yields", "purchased", "crust", "snack", "pot",
        "school", "fun", "bunch", "head", "pint", "refuse",
    ]

    private static func orderKey(_ portion: Portion, context: OrderContext) -> [Int] {
        let nameWordList = outsideWords(portion)
        let nameWords = Set(nameWordList)
        let unit = amountUnit(for: portion)
        let sizeRank = nameWordList.compactMap { sizeRanks[$0] }.min() ?? 1
        let head = nameWordList.first { sizeRanks[$0] == nil && !fillerWords.contains($0) }

        let tier: Int
        if !nameWords.isDisjoint(with: oddWords) || portion.gramWeight > 1000 {
            tier = 4
        } else if isOneOfTheThing(portion, head: head, words: nameWords, context: context) {
            tier = 0
        } else if !nameWords.isDisjoint(with: servingWords) {
            let isTinyPiece = portion.gramWeight < 15 && context.hasPlainCup
                && nameWords.isDisjoint(with: ["clove", "cloves", "pat"])  // small on purpose
            tier = isTinyPiece ? 3 : 1
        } else if isSpoon(portion) {
            tier = context.isSpooned ? 1 : 3
        } else if unit == .ounces || isPlainCup(portion) {
            tier = 2
        } else {
            tier = 3
        }

        let unitOrder = (tier >= 2 && unit == .count) ? 1 : 0
        // Among the likely picks, plain names first: "slice" before "cracker-size slice". Past
        // those, USDA's names are too varied for this to help ("package" vs "flavor packet").
        var qualifiers = tier <= 2
            ? nameWordList.filter { !plainNameWords.contains($0) && !context.foodWords.contains(singular($0)) }.count
            : 0
        if portion.name.lowercased().contains("with ice") { qualifiers += 1 }
        return [tier, unitOrder, qualifiers, sizeRank]
    }

    /// "egg", "medium bagel", "fruit" (an orange), or just a size ("medium" apple). A named unit
    /// needs 15 g, so "nugget" counts but "grape" doesn't. A bare size or item word needs 30 g
    /// when there's a cup to fall back on, so an "extra large" strawberry doesn't beat a cup but a
    /// "medium" tortilla still counts. For drinks a bare size is a café cup size.
    private static func isOneOfTheThing(_ portion: Portion, head: String?, words: Set<String>, context: OrderContext) -> Bool {
        guard portion.gramWeight <= 400,
              words.isDisjoint(with: notAnItemWords),
              portion.name.first?.isNumber != true  // "1/2 chicken"
        else { return false }
        let itemMinimum: Double = context.hasPlainCup ? 30 : 15
        guard let head else { return !context.isDrink && portion.gramWeight >= itemMinimum }
        if wholeItemWords.contains(head) { return portion.gramWeight >= itemMinimum }
        return context.foodWords.contains(singular(head)) && portion.gramWeight >= 15
    }

    private static func isPlainCup(_ portion: Portion) -> Bool {
        let words = outsideWords(portion)
        return words.first == "cup" && Set(words).isDisjoint(with: preparedCupWords)
            && Set(words).isDisjoint(with: oddWords)
    }

    private static func isSpoon(_ portion: Portion) -> Bool {
        outsideWords(portion).first.map(spoonWords.contains) ?? false
    }

    /// Words outside parentheses: "medium slice (yield after cooking)" is a slice, not a yield.
    private static func outsideWords(_ portion: Portion) -> [String] {
        words(in: portion.name.replacing(#/\([^)]*\)/#, with: " "))
    }

    private static func words(in text: String) -> [String] {
        text.lowercased().split { !$0.isLetter }.map(String.init)
    }

    /// "eggs" → "egg", "cherries" → "cherry", "tomatoes" → "tomato".
    private static func singular(_ word: String) -> String {
        if word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("s") && !word.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    /// Pill labels for portions, dropping measurement details in parentheses that USDA adds
    /// ("1 slice (6-1/2\" x 2-3/8\" x 3/8\")" → "1 slice"). Keeps the full name when the short one
    /// would match another portion's label.
    static func pillLabels(for portions: [Portion]) -> [String] {
        let short = portions.map { shortName($0.name) }
        return zip(portions, short).map { portion, label in
            short.filter { $0 == label }.count > 1 ? portion.name : label
        }
    }

    static func shortName(_ name: String) -> String {
        let trimmed = name
            .replacing(#/\s*\([^)]*[\d"][^)]*\)/#, with: "")
            .trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? name : trimmed
    }

    /// "½", "1", "1½", "150".
    static func label(for amount: Double) -> String {
        let whole = amount.rounded(.down)
        let fraction = amount - whole
        let fractionText: String
        switch fraction {
        case 0: fractionText = ""
        case 0.25: fractionText = "¼"
        case 0.5: fractionText = "½"
        case 0.75: fractionText = "¾"
        default: return amount.formatted(.number.precision(.fractionLength(0...2)))
        }
        return (whole == 0 && !fractionText.isEmpty ? "" : String(Int(whole))) + fractionText
    }

    /// Which portions to show before "+N more": the one picked, grams, and the first few others,
    /// kept in list order. Short lists are shown in full, since "+1 more" saves nothing.
    static func featuredPortionIndices(_ portions: [Portion], anchor: Portion?, limit: Int = 4) -> [Int] {
        guard portions.count > limit + 1 else { return Array(portions.indices) }
        var keep: [Int] = []
        if let anchor, let index = portions.firstIndex(where: { isSamePortion(anchor, $0) }) {
            keep.append(index)
        }
        if let grams = portions.firstIndex(where: isGramPortion), !keep.contains(grams) {
            keep.append(grams)
        }
        for index in portions.indices where keep.count < limit && !keep.contains(index) {
            keep.append(index)
        }
        return keep.sorted()
    }

    /// What's about to be logged, for the Add button: "2 × 1 slice", "150 g", "1½ cup".
    static func summary(amount: Double, portionName: String) -> String {
        let name = shortName(portionName)
        let separator = name.first?.isNumber == true ? " × " : " "
        return label(for: amount) + separator + name
    }

    /// True when the current choice is exactly what was logged last time for this food.
    static func matchesLastTime(portion: Portion?, amount: Double, lastLogged: LastLogged?) -> Bool {
        guard let portion, let lastLogged else { return false }
        return isSamePortion(portion, name: lastLogged.portionName, gramWeight: lastLogged.gramWeight)
            && abs(amount - lastLogged.amount) < 0.001
    }

    /// Reads what the user typed, accepting either "." or "," as the decimal mark. Nil for
    /// anything that isn't a positive number.
    static func parseAmount(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned), value > 0, value.isFinite else { return nil }
        return value
    }

    /// The text shown in the amount field for a value, e.g. "1.5" (no fraction glyphs, so it can be edited).
    static func editableText(for amount: Double) -> String {
        amount.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}
