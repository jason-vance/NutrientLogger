//
//  FtsQueryGenerator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class FtsQueryGenerator {

    static func isStopWord(_ word: String) -> Bool {
        stopWords.contains(word.lowercased())
    }

    private static let stopWords: Set<String> = [
        "with", "and", "in", "of", "the", "a", "an", "or", "for",
        "to", "on", "at", "by", "no", "not"
    ]

    private static let abbreviations: [String: String] = [
        "oj": "orange juice",
        "pb": "peanut butter",
        "pbj": "peanut butter jelly",
        "pb&j": "peanut butter jelly",
        "evoo": "extra virgin olive oil",
        "chx": "chicken",
        "broc": "broccoli",
        "cuke": "cucumber",
        "parm": "parmesan",
        "veg": "vegetable",
        "vegs": "vegetables",
        "bbq": "barbecue",
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
            .joined(separator: " AND ")
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
        let expanded = expandAbbreviations(withoutQuantities(query))
        let tokens = withoutPunctuation(expanded)
            .split(separator: " ")
            .map { String($0) }
        let filtered = tokens.filter { !stopWords.contains($0.lowercased()) }
        let result = (filtered.isEmpty ? tokens : filtered).unique()
        return result
    }

    // Words that mean the same food but aren't spelled the way USDA names it.
    // Only used as a fallback when the user's own words find nothing.
    static let synonyms: [String: String] = [
        "coke": "soft drink cola",
        "soda": "soft drink",
        "yoghurt": "yogurt",
        "yoghurts": "yogurt",
        "aubergine": "eggplant",
        "courgette": "zucchini",
        "prawn": "shrimp",
        "prawns": "shrimp",
        "porridge": "oatmeal",
        "crisps": "chips",
        "garbanzo": "chickpeas",
        "coriander": "cilantro",
        "capsicum": "pepper",
        "donut": "doughnut",
        "donuts": "doughnut",
        "omelette": "omelet",
        "omelettes": "omelet",
        "milkshake": "milk shake",
        "milkshakes": "milk shake",
        "blt": "bacon lettuce tomato",
        "cheesesteak": "steak sandwich",
        "tater": "potato",
        "veggie": "vegetable",
        "veggies": "vegetables",
        "ipa": "beer",
        "skyr": "yogurt greek plain",
        "carnitas": "pork shoulder cooked",
        "tbone": "t bone steak",
        // Cut words USDA leaves out of fish and meat names: "salmon fillet" -> salmon.
        "fillet": "",
        "fillets": "",
        "filet": "",
        "filets": "",
    ]

    // Whole searches USDA names differently. Keyed by the tokenized, lowercased query.
    // Also only a fallback.
    static let phraseSynonyms: [String: String] = [
        "cold brew": "iced coffee brewed",
        "string cheese": "mozzarella part skim",
        "bone broth": "broth",
        "buffalo wings": "chicken wing",
        "buffalo wing": "chicken wing",
        "new york strip": "beef top loin steak",
        "ny strip": "beef top loin steak",
        "carne asada": "beef steak",
        "breakfast sandwich": "egg cheese",
        "sea salt": "salt table",
        "pink salt": "salt table",
        "la croix": "carbonated water unsweetened",
        "electrolyte drink": "sports drink",
        "caramel macchiato": "coffee macchiato sweetened",
        "pumpkin spice latte": "coffee latte flavored",
        "psl": "coffee latte flavored",
        "mct oil": "coconut oil",
        "poke bowl": "tuna fresh raw",
    ]

    // Words for how food was served, dropped when followed by "of": "a bowl of cereal" -> cereal.
    // "Can" stays, since it's what matches "canned" in "can of tuna".
    private static let servingUnits: Set<String> = [
        "bowl", "bowls", "glass", "glasses", "handful", "handfuls", "plate", "plates",
        "mug", "mugs", "bottle", "bottles", "pinch", "dash", "splash", "bag", "bags", "packet",
        "packets", "stick", "sticks", "box", "carton", "jar", "spoonful", "spoonfuls", "shot", "shots",
        "pint", "pints", "bar", "bars", "cup", "cups", "slice", "slices", "piece", "pieces", "serving",
        "servings", "scoop", "scoops", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon",
        "teaspoons", "oz", "ounce", "ounces", "g", "gram", "grams", "lb", "lbs", "pound", "pounds",
    ]

    // Spelled-out amounts, dropped like digits when a unit follows: "two slices of bacon" -> bacon.
    // Not before a food, so "Five Guys" stays whole.
    private static let numberWords: Set<String> = [
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "twelve",
        "half", "couple", "few", "dozen",
    ]

    private static let quantityUnits: Set<String> = [
        "cup", "cups", "c", "tbsp", "tablespoon", "tablespoons", "tsp", "teaspoon", "teaspoons",
        "oz", "ounce", "ounces", "g", "gram", "grams", "lb", "lbs", "pound", "pounds", "ml",
        "slice", "slices", "piece", "pieces", "serving", "servings", "scoop", "scoops",
        "large", "medium", "small", "x",
    ]

    // "2 eggs", "1 cup rice", "100g chicken", "a bowl of cereal" -> drop the amount so it doesn't
    // have to match the food's name. A number keeps its place when it's part of the name, like
    // "2% milk", and "half and half" stays whole.
    static func withoutQuantities(_ query: String) -> String {
        let tokens = query.split(separator: " ").map(String.init)
        var kept: [String] = []
        var afterNumber = false
        for (index, token) in tokens.enumerated() {
            let lower = token.lowercased()
            let next = index + 1 < tokens.count ? tokens[index + 1].lowercased() : nil
            if lower.wholeMatch(of: #/\d+([./]\d+)?(g|oz|ml|x)?/#) != nil {
                afterNumber = true
                continue
            }
            if numberWords.contains(lower), let next,
               quantityUnits.contains(next) || servingUnits.contains(next) {
                afterNumber = true
                continue
            }
            if afterNumber && (quantityUnits.contains(lower) || servingUnits.contains(lower)) {
                continue
            }
            if servingUnits.contains(lower) && next == "of" {
                continue
            }
            afterNumber = false
            kept.append(token)
        }
        return kept.isEmpty ? query : kept.joined(separator: " ")
    }

    static func expandAbbreviations(_ query: String) -> String {
        query.split(separator: " ")
            .map { token in
                abbreviations[token.lowercased()] ?? String(token)
            }
            .joined(separator: " ")
    }

    static func stemmedWithWildcards(_ token: String) -> String {
        let alternatives = [token] + stems(of: token)
        guard alternatives.count > 1 else { return withWildcards(token) }
        return "(" + alternatives.map(withWildcards).joined(separator: " OR ") + ")"
    }

    /// The other forms a word's prefix search should cover. Usually one stem, but "ies" words get
    /// two: "berries" -> "berry" and "cookies" -> "cookie" both happen in food names.
    static func stems(of token: String) -> [String] {
        guard let stemmed = stemToken(token).stemmed else { return [] }
        if token.lowercased().hasSuffix("ies") {
            return [stemmed, String(token.dropLast())]
        }
        return [stemmed]
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
        } else if lower.hasSuffix("y") && token.count > 3,
                  let beforeY = lower.dropLast().last, !"aeiou".contains(beforeY) {
            // "strawberry" -> "strawberri", so the prefix also matches "Strawberries"
            stemmed = String(token.dropLast(1)) + "i"
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
