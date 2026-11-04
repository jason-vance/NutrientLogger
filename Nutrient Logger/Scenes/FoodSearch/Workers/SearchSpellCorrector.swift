//
//  SearchSpellCorrector.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import Foundation

// Fixes typos like "brocoli" or "chiken" by finding the closest word that actually
// appears in the food database. Only words that match nothing are corrected, so a
// word the user is still typing ("chick") is left alone.
final class SearchSpellCorrector {

    // word -> number of foods whose name contains it
    private let wordCounts: [String: Int]
    private let sortedWords: [String]
    private let wordsByLength: [Int: [String]]

    init(wordCounts: [String: Int]) {
        self.wordCounts = wordCounts
        self.sortedWords = wordCounts.keys.sorted()
        self.wordsByLength = Dictionary(grouping: wordCounts.keys, by: \.count)
    }

    convenience init(foodNames: [String]) {
        var counts: [String: Int] = [:]
        for name in foodNames {
            for word in Set(Self.words(in: name)) {
                counts[word, default: 0] += 1
            }
        }
        self.init(wordCounts: counts)
    }

    // Splits a name the same way the search index does: lowercase, letters and digits only,
    // accents removed.
    static func words(in text: String) -> [String] {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    func correct(_ token: String) -> String? {
        let word = token.lowercased()
        guard word.count >= 4,
              !word.allSatisfy(\.isNumber),
              !hasWord(startingWith: word)
        else { return nil }

        let maxDistance = word.count <= 7 ? 1 : 2
        var best: (distance: Int, count: Int, word: String)?

        for length in (word.count - maxDistance)...(word.count + maxDistance) {
            for candidate in wordsByLength[length] ?? [] {
                let distance = Self.editDistance(word, candidate, max: maxDistance)
                guard distance <= maxDistance else { continue }
                let count = wordCounts[candidate] ?? 0
                if let current = best {
                    if distance > current.distance { continue }
                    if distance == current.distance && count < current.count { continue }
                    if distance == current.distance && count == current.count && candidate > current.word { continue }
                }
                best = (distance, count, candidate)
            }
        }
        return best?.word
    }

    private func hasWord(startingWith prefix: String) -> Bool {
        var low = 0
        var high = sortedWords.count
        while low < high {
            let mid = (low + high) / 2
            if sortedWords[mid] < prefix { low = mid + 1 } else { high = mid }
        }
        return low < sortedWords.count && sortedWords[low].hasPrefix(prefix)
    }

    // Edits needed to turn `a` into `b` (insert, delete, substitute, or swap two neighbors).
    // Stops early and returns max + 1 once the answer is known to be over `max`.
    static func editDistance(_ a: String, _ b: String, max: Int) -> Int {
        let a = Array(a)
        let b = Array(b)
        if abs(a.count - b.count) > max { return max + 1 }
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var twoRowsBack = [Int](repeating: 0, count: b.count + 1)
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            var rowMin = current[0]
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                var value = Swift.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    value = Swift.min(value, twoRowsBack[j - 2] + 1)
                }
                current[j] = value
                rowMin = Swift.min(rowMin, value)
            }
            if rowMin > max { return max + 1 }
            twoRowsBack = previous
            previous = current
        }
        return previous[b.count]
    }
}
