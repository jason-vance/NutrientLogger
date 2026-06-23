//
//  FtsQueryGenerator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class FtsQueryGenerator {

    private static let stopWords: Set<String> = [
        "with", "and", "in", "of", "the", "a", "an", "or", "for",
        "to", "on", "at", "by", "no", "not"
    ]

    private static let abbreviations: [String: String] = [
        "oj": "orange juice",
        "pb": "peanut butter",
        "pbj": "peanut butter jelly",
        "evoo": "extra virgin olive oil",
        "chx": "chicken",
        "broc": "broccoli",
        "cuke": "cucumber",
        "parm": "parmesan",
        "veg": "vegetable",
        "vegs": "vegetables",
    ]

    private static let doNotStem: Set<String> = [
        "cheese", "rice", "juice", "sauce", "moose", "goose",
        "mousse", "couscous", "hummus", "asparagus", "citrus",
        "lettuce", "produce", "quinoa", "granose", "purpose",
    ]

    public static func generateFrom(_ query: String) -> String {
        let tokens = tokenize(query)

        return tokens
            .map { stemmedWithWildcards($0) }
            .joined(separator: " ")
    }

    public static func generateExactFrom(_ query: String) -> String {
        tokenize(query).joined(separator: " ")
    }

    public static func generatePhraseFrom(_ query: String) -> String? {
        let tokens = tokenize(query)
        guard tokens.count >= 2 else { return nil }
        return "\"" + tokens.joined(separator: " ") + "\""
    }

    static func tokenize(_ query: String) -> [String] {
        let expanded = expandAbbreviations(query)
        let tokens = withoutPunctuation(expanded)
            .split(separator: " ")
            .map { String($0) }
        let filtered = tokens.filter { !stopWords.contains($0.lowercased()) }
        let result = (filtered.isEmpty ? tokens : filtered).unique()
        return result
    }

    static func expandAbbreviations(_ query: String) -> String {
        query.split(separator: " ")
            .map { token in
                abbreviations[token.lowercased()] ?? String(token)
            }
            .joined(separator: " ")
    }

    static func stemmedWithWildcards(_ token: String) -> String {
        let (original, stemmed) = stemToken(token)
        if let stemmed = stemmed {
            return "(\(withWildcards(original)) OR \(withWildcards(stemmed)))"
        }
        return withWildcards(original)
    }

    static func stemToken(_ token: String) -> (original: String, stemmed: String?) {
        let lower = token.lowercased()

        if doNotStem.contains(lower) {
            return (token, nil)
        }

        let stemmed: String?

        if lower.hasSuffix("ies") && token.count > 4 {
            stemmed = String(token.dropLast(3)) + "y"
        } else if lower.hasSuffix("ves") && token.count > 4 {
            stemmed = String(token.dropLast(3)) + "f"
        } else if lower.hasSuffix("oes") && token.count > 4 {
            stemmed = String(token.dropLast(2))
        } else if lower.hasSuffix("ses") && !lower.hasSuffix("sses") && token.count > 4 {
            stemmed = String(token.dropLast(1))
        } else if lower.hasSuffix("es") && token.count > 3 {
            stemmed = String(token.dropLast(2))
        } else if lower.hasSuffix("s") && !lower.hasSuffix("ss") && token.count > 2 {
            stemmed = String(token.dropLast(1))
        } else {
            stemmed = nil
        }

        if let stemmed = stemmed, stemmed.lowercased() == lower {
            return (token, nil)
        }

        return (token, stemmed)
    }

    public static func cleanProductName(_ name: String, brand: String? = nil) -> String {
        var cleaned = name

        if let brand = brand, !brand.isEmpty {
            for part in brand.split(separator: ",") {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if let range = cleaned.range(of: trimmed, options: .caseInsensitive) {
                    cleaned.replaceSubrange(range, with: "")
                }
            }
        }

        let sizePattern = #"\d+\.?\d*\s*(?:oz|fl\s*oz|g|kg|ml|l|lb|lbs|ct|count|pk|pack)\b"#
        if let regex = try? NSRegularExpression(pattern: sizePattern, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                range: NSRange(cleaned.startIndex..., in: cleaned),
                withTemplate: ""
            )
        }

        let packagingWords: Set<String> = [
            "organic", "natural", "original", "classic", "traditional",
            "family", "size", "pack", "value", "box", "bag", "can",
            "bottle", "jar", "container", "pouch", "frozen", "fresh",
            "canned", "dried", "instant", "ready", "made", "homestyle",
            "premium", "select", "choice", "fancy", "deluxe", "lite",
            "light", "reduced", "free", "sugar", "unsweetened",
        ]

        let words = cleaned
            .split(separator: " ")
            .map { String($0) }
            .filter { !packagingWords.contains($0.lowercased()) }

        return words.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func generateOrFrom(_ query: String) -> String {
        let tokens = tokenize(query)
        guard !tokens.isEmpty else { return "" }

        return tokens
            .map { stemmedWithWildcards($0) }
            .joined(separator: " OR ")
    }

    public static func withWildcards<T: StringProtocol>(_ query: T) -> String {
        return query + "*"
    }

    public static func withoutPunctuation<T: StringProtocol>(_ query: T) -> String {
        String(query.filter { !$0.isPunctuation })
    }
}
