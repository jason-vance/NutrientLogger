//
//  FoodSearchRanker.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import Foundation

// Orders USDA search results so the plain, everyday version of a food comes first:
// "banana" should lead with "Banana, raw", not "Bananas, dehydrated, or banana powder".
enum FoodSearchRanker {

    // Words that mark a processed or unusual form. Pushed down unless the user typed them.
    private static let unusualFormWords: Set<String> = [
        "dried", "dehydrated", "powder", "powdered", "frozen", "canned", "concentrate",
        "meatless", "babyfood", "baby", "infant", "toddler", "formula", "mix", "dry",
        "imitation", "substitute", "flour", "unprepared", "juice", "nectar", "ingredient",
        "flavored", "dessert", "pastries",
    ]

    // Words that mark the everyday form of a food.
    private static let everydayFormWords: Set<String> = [
        "raw", "fresh", "brewed", "plain", "whole", "cooked", "regular",
    ]

    // Suffixes that still count as the same word: "egg" covers "eggs", "strawberri" covers "strawberries".
    private static let pluralSuffixes: Set<String> = ["", "s", "es", "ies", "y"]

    static func rank(_ foods: [FdcSearchableFood], tokens: [String]) -> [FdcSearchableFood] {
        let queryWords = tokens.map { $0.lowercased() }
        let variants = queryWords.map(variants(of:))

        let ranked = foods.enumerated()
            .map { index, food in (food, sortKey(food.description, queryWords: queryWords, variants: variants, index: index)) }
            .sorted { $0.1.lexicographicallyPrecedes($1.1) }
            .map(\.0)

        // USDA's two datasets often carry the same food under the same name. Show it once.
        var seenNames = Set<String>()
        return ranked.filter { seenNames.insert($0.description.lowercased()).inserted }
    }

    private static func sortKey(
        _ description: String,
        queryWords: [String],
        variants: [[String]],
        index: Int
    ) -> [Int] {
        let parts = description.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
        let words = Set(SearchSpellCorrector.words(in: description))
        let firstPartWords = SearchSpellCorrector.words(in: parts.first ?? "")

        // "Rice, brown, cooked" is brown rice; "Beans and brown rice" is a dish that contains it.
        let firstPartIsJustTheQuery = !firstPartWords.isEmpty
            && firstPartWords.allSatisfy { isCovered($0, by: variants) || FtsQueryGenerator.isStopWord($0) }

        // Query words found only as the start of a longer word: "egg" in "eggplant", "pita" in "pitanga".
        let partialMatchCount = variants.filter { wordVariants in
            !words.contains { isCovered($0, by: [wordVariants]) }
        }.count

        let unusualCount = words.filter { unusualFormWords.contains($0) && !queryWords.contains($0) }.count
        var everydayScore = 0
        if words.contains("nfs") { everydayScore += 1 }  // USDA's "not further specified" = the generic entry
        if !everydayWords(words, in: description).isDisjoint(with: everydayFormWords) { everydayScore += 1 }

        return [
            partialMatchCount,
            firstPartIsJustTheQuery ? 0 : 1,
            unusualCount,
            positionScore(parts: parts, variants: variants),
            -everydayScore,
            hasUntypedBrand(description, variants: variants) ? 1 : 0,
            parts.count,
            description.count,
            index,
        ]
    }

    // "Whole" marks the everyday form in "Egg, whole" and "Milk, whole", but not in "whole wheat"
    // or "whole grain", which are a specific kind of the food.
    private static func everydayWords(_ words: Set<String>, in description: String) -> Set<String> {
        let lower = description.lowercased()
        let isWholeGrain = ["whole wheat", "whole-wheat", "whole grain", "whole-grain"].contains { lower.contains($0) }
        return isWholeGrain ? words.subtracting(["whole"]) : words
    }

    // Lower is better. Each query word adds the index of the comma-separated part where it
    // first appears as a word prefix, or the part count if it never does.
    private static func positionScore(parts: [String], variants: [[String]]) -> Int {
        var score = 0
        for wordVariants in variants {
            var bestIndex = parts.count
            for (i, part) in parts.enumerated() {
                let partWords = part.split(separator: " ")
                if partWords.contains(where: { word in wordVariants.contains { word.hasPrefix($0) } }) {
                    bestIndex = i
                    break
                }
            }
            score += bestIndex
        }
        return score
    }

    private static func isCovered(_ word: String, by variants: [[String]]) -> Bool {
        variants.contains { wordVariants in
            wordVariants.contains { variant in
                word.hasPrefix(variant) && pluralSuffixes.contains(String(word.dropFirst(variant.count)))
            }
        }
    }

    // Brand names are in capitals in USDA data ("SILK Coffee, soymilk", "PIZZA HUT 14\" ...").
    private static func hasUntypedBrand(_ description: String, variants: [[String]]) -> Bool {
        description
            .split { !$0.isLetter }
            .filter { $0.count >= 3 && $0 != "NFS" && $0.allSatisfy(\.isUppercase) }
            .contains { !isCovered($0.lowercased(), by: variants) }
    }

    private static func variants(of word: String) -> [String] {
        [word] + FtsQueryGenerator.stems(of: word).map { $0.lowercased() }
    }
}
