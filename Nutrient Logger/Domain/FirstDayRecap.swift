//
//  FirstDayRecap.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import Foundation

/// What the user sees after their first full day of logging: the few nutrients their food was
/// shortest on ("You're low on magnesium and potassium today"), plus a count of what else Premium
/// would show. This is the moment the app's value becomes concrete, so the trial offer sits here.
struct FirstDayRecap: Equatable {

    struct Gap: Equatable, Identifiable {
        let id: String
        let name: String
        /// Fraction of the daily goal reached, e.g. 0.38 for 38%.
        let percentOfGoal: Double
    }

    static let maxGapsShown = 3

    /// The biggest gaps, lowest first. Named for everyone, subscribed or not.
    let shownGaps: [Gap]
    /// Further low nutrients beyond the ones shown.
    let moreLowCount: Int
    let highCount: Int
    let balanceCount: Int

    init(lows: [Gap], highCount: Int, balanceCount: Int) {
        let sorted = lows.sorted { $0.percentOfGoal < $1.percentOfGoal }
        shownGaps = Array(sorted.prefix(Self.maxGapsShown))
        moreLowCount = max(0, sorted.count - Self.maxGapsShown)
        self.highCount = highCount
        self.balanceCount = balanceCount
    }

    var headline: String {
        guard !shownGaps.isEmpty else {
            return "You got at least half of every vitamin and mineral today"
        }
        return "You're low on \(Self.naturalList(shownGaps.map { Self.inSentence($0.name) })) today"
    }

    /// Everything the recap doesn't name: extra lows, highs and balances. Premium shows these.
    var unnamedCount: Int { moreLowCount + highCount + balanceCount }

    /// e.g. "2 more running low, 1 over the limit and 1 out of balance". Nil when there's nothing.
    var unnamedSummary: String? {
        var parts: [String] = []
        if moreLowCount > 0 { parts.append("\(moreLowCount) more running low") }
        if highCount > 0 { parts.append("\(highCount) over the limit") }
        if balanceCount > 0 { parts.append("\(balanceCount) out of balance") }
        return parts.isEmpty ? nil : Self.naturalList(parts)
    }

    /// Ties the shown gaps to the user's diet, e.g. "Vitamin C and folate are common gaps on a
    /// carnivore diet, so they sit at the top of your Nutrition tab." Names only the shown gaps the
    /// diet is known to run short on (its promoted nutrients). Nil when none match.
    func dietNote(for diet: NutritionDietPreset?) -> String? {
        guard let diet, let phrase = diet.gapPhrase else { return nil }
        let dietGapIds = Set(diet.promotedNutrients.values.joined())
        let names = shownGaps.filter { dietGapIds.contains($0.id) }.map { Self.inSentence($0.name) }
        guard let first = names.first else { return nil }

        let list = Self.naturalList([first.prefix(1).uppercased() + first.dropFirst()] + names.dropFirst())
        return names.count == 1
            ? "\(list) is a common gap \(phrase), so it sits at the top of your Nutrition tab."
            : "\(list) are common gaps \(phrase), so they sit at the top of your Nutrition tab."
    }

    /// "a", "a and b", "a, b and c".
    static func naturalList(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default: return items.dropLast().joined(separator: ", ") + " and " + items.last!
        }
    }

    /// Lowercases a nutrient name for use mid-sentence, keeping letter codes:
    /// "Vitamin D" → "vitamin D", "Pantothenic Acid" → "pantothenic acid", "Vitamin B12" → "vitamin B12".
    static func inSentence(_ name: String) -> String {
        name.split(separator: " ", omittingEmptySubsequences: false)
            .map { word in
                let isCode = word.count <= 3 && word.allSatisfy { $0.isUppercase || $0.isNumber }
                return isCode ? String(word) : word.lowercased()
            }
            .joined(separator: " ")
    }
}

enum FirstDayRecapTrigger {

    static let hasShownKey = "firstDayRecapShown"

    /// Shows once, on the first day the user logs breakfast, lunch and dinner (see `FullLoggingDay`).
    static func shouldShow(isFullLoggingDay: Bool, hasShownBefore: Bool) -> Bool {
        isFullLoggingDay && !hasShownBefore
    }
}

extension User {

    /// Nutrient goals depend on age, which new users haven't entered yet. Without one there are no
    /// goals, so every nutrient would look "on track". Fill in a ~30-year-old adult (sex left
    /// unknown) so the gaps reflect general adult targets until the user adds their own details.
    /// Never persisted.
    var withReferenceAgeIfMissing: User {
        guard birthdate == nil else { return self }
        var copy = self
        copy.birthdate = SimpleDate(year: 1995, month: 6, day: 15)
        return copy
    }
}
