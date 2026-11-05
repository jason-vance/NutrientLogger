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

    static func defaultAmount(for portion: Portion) -> Double {
        isGramPortion(portion) ? 100 : 1
    }

    static func quickAmounts(for portion: Portion?) -> [Double] {
        guard let portion else { return [] }
        return isGramPortion(portion) ? [50, 100, 150, 200] : [0.5, 1, 1.5, 2, 3]
    }

    /// Switching between grams and a counted portion ("1 cup") would otherwise turn
    /// "1 cup" into "1 g" or "100 g" into "100 cups".
    static func amountAfterSwitching(from old: Portion?, to new: Portion, currentAmount: Double) -> Double {
        guard let old, isGramPortion(old) != isGramPortion(new) else { return currentAmount }
        return defaultAmount(for: new)
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
