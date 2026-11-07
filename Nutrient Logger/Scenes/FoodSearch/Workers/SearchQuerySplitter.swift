//
//  SearchQuerySplitter.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// USDA has no single food for "bagel with cream cheese" or "avocado toast", so those searches
/// found nothing. When that happens this works out the foods the search names, so each can be
/// searched and logged on its own:
///
/// - "bagel with cream cheese" -> bagel, cream cheese (split at "and", "with", "on", ...)
/// - "peanut butter toast" -> peanut butter, toast (the split where both halves find the most)
/// - "starbucks latte" -> latte (words that appear in no food are dropped)
/// - "loaded baked potato" -> baked potato (a describing word is dropped, never searched alone)
///
/// Only used after the normal search and the typo/synonym retry both found nothing.
enum SearchQuerySplitter {

    /// Searches a candidate. Returns the query that found foods (the candidate itself, or a
    /// corrected version) and how many, or nil when it finds nothing.
    typealias Finder = (String) -> (query: String, count: Int)?

    static let connectors: Set<String> = ["and", "with", "on", "plus", "n", "w"]

    /// Words that describe a food rather than name one. Never searched as a part of their own,
    /// since "Roasted" alone would list every roasted food.
    static let describingWords: Set<String> = [
        "baked", "boiled", "braised", "breaded", "broiled", "cold", "cooked", "creamy", "crispy",
        "diet", "dried", "fat", "free", "fresh", "fried", "frozen", "grilled", "homemade", "hot",
        "iced", "large", "lean", "light", "loaded", "low", "mashed", "medium", "organic", "plain",
        "poached", "pulled", "raw", "roast", "roasted", "sauteed", "scrambled", "small", "smoked",
        "spicy", "steamed", "stuffed", "sweet", "toasted", "whole", "bowl", "bowls",
        "can", "cans", "canned",
    ]

    /// Words that name a food when searched alone: "buttered toast" -> butter + toast.
    static let partWords: [String: String] = [
        "buttered": "butter",
        "cheesy": "cheese",
    ]

    static func parts(of query: String, find: @escaping Finder) -> [SearchQueryPart] {
        var cache: [String: (query: String, count: Int)?] = [:]
        let cachedFind: Finder = { candidate in
            if let hit = cache[candidate] { return hit }
            let result = find(candidate)
            cache[candidate] = result
            return result
        }

        let chunks = chunks(of: query)
        let parts: [SearchQueryPart]
        if chunks.count >= 2 {
            parts = chunks.compactMap { resolveWhole($0, find: cachedFind) }
        } else if let only = chunks.first {
            parts = resolveSingle(only, find: cachedFind)
        } else {
            parts = []
        }

        var seen = Set<String>()
        return parts.filter { seen.insert($0.query.lowercased()).inserted }
    }

    /// The query's words, split into groups at connector words. Amounts ("2 slices of"), filler
    /// words and cut words ("fillet") are dropped, and describing words that name a food swapped
    /// in ("buttered" -> "butter"). Other synonyms are left to the finder's correction, so section
    /// titles keep the user's words ("Coke", not "Soft drink cola").
    static func chunks(of query: String) -> [[String]] {
        let expanded = FtsQueryGenerator.expandAbbreviations(FtsQueryGenerator.withoutQuantities(query))
        let spaced = expanded
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "+", with: " and ")
            .replacingOccurrences(of: "w/", with: " with ", options: .caseInsensitive)
        let cleaned = FtsQueryGenerator.withoutPunctuation(spaced)

        var chunks: [[String]] = [[]]
        for raw in cleaned.lowercased().split(separator: " ").map(String.init) {
            if connectors.contains(raw) {
                if !(chunks.last?.isEmpty ?? true) { chunks.append([]) }
                continue
            }
            if FtsQueryGenerator.isStopWord(raw) || FtsQueryGenerator.synonyms[raw] == "" { continue }
            chunks[chunks.count - 1].append(partWords[raw] ?? raw)
        }
        return chunks.filter { !$0.isEmpty }
    }

    /// A group from between connectors: searched whole, or with its unknown and describing words
    /// dropped. Never split further, since the user already marked where one food ends.
    private static func resolveWhole(_ words: [String], find: Finder) -> SearchQueryPart? {
        if let part = part(words, find: find) { return part }
        let known = knownWords(words, find: find)
        if known != words, let part = part(known, find: find) { return part }
        return withoutDescribingWords(known, find: find)
    }

    private static func resolveSingle(_ words: [String], find: Finder) -> [SearchQueryPart] {
        let known = knownWords(words, find: find)
        if known != words, let part = part(known, find: find) { return [part] }
        if let split = bestSplit(known, find: find) { return split }
        if let part = withoutDescribingWords(known, find: find) { return [part] }
        return []
    }

    /// Drops the words that appear in no food at all: "starbucks latte" -> latte.
    private static func knownWords(_ words: [String], find: Finder) -> [String] {
        words.filter { find($0) != nil }
    }

    /// Drops describing words one at a time from the left: "loaded baked potato" -> baked potato.
    private static func withoutDescribingWords(_ words: [String], find: Finder) -> SearchQueryPart? {
        var remaining = words
        while let index = remaining.firstIndex(where: describingWords.contains), remaining.count > 1 {
            remaining.remove(at: index)
            if let part = part(remaining, find: find) { return part }
        }
        return nil
    }

    /// Splits into two foods where both halves find something, picking the split whose weaker half
    /// finds the most: "peanut butter toast" -> peanut butter + toast, not peanut + butter toast.
    private static func bestSplit(_ words: [String], find: Finder) -> [SearchQueryPart]? {
        guard words.count >= 2 else { return nil }
        var best: (parts: [SearchQueryPart], score: Int)?
        for index in 1..<words.count {
            let left = Array(words[..<index])
            let right = Array(words[index...])
            guard !left.allSatisfy(describingWords.contains),
                  !right.allSatisfy(describingWords.contains),
                  let leftHit = find(left.joined(separator: " ")),
                  let rightHit = find(right.joined(separator: " "))
            else { continue }

            let score = min(leftHit.count, rightHit.count)
            if score > (best?.score ?? 0) {
                best = ([named(left, leftHit.query), named(right, rightHit.query)], score)
            }
        }
        return best?.parts
    }

    private static func part(_ words: [String], find: Finder) -> SearchQueryPart? {
        guard !words.isEmpty, let hit = find(words.joined(separator: " ")) else { return nil }
        return named(words, hit.query)
    }

    private static func named(_ words: [String], _ query: String) -> SearchQueryPart {
        let name = words.joined(separator: " ")
        return SearchQueryPart(name: name.prefix(1).uppercased() + name.dropFirst(), query: query)
    }
}
