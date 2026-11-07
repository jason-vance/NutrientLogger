//
//  EverydayFoodNames.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

// USDA names some everyday foods in ways ranking can't guess. Plain toast is "Bread, white,
// toasted", so "toast" would otherwise lead with French toast. For these searches the listed
// entries go first and the usual results follow.
//
// Keep this list short. Add to it from real searches where people pick a result far down the
// list (the `search_result_picked` event), not from guesses.
enum EverydayFoodNames {

    /// What people type → exact USDA descriptions to show first, in order.
    static let leadingEntries: [String: [String]] = [
        "toast": ["Bread, white, toasted", "Bread, whole wheat, toasted"],
        "bread": ["Bread, white", "Bread, whole wheat"],
        "fries": ["Potato, french fries, NFS"],
        "burger": ["Hamburger, NFS", "Cheeseburger, NFS"],
        "burgers": ["Hamburger, NFS", "Cheeseburger, NFS"],
        "soda": ["Soft drink, NFS", "Soft drink, cola", "Soft drink, NFS, diet"],
        "black coffee": ["Coffee, brewed"],
        "espresso": ["Coffee, espresso"],
        "tea": ["Tea, hot, leaf, black", "Tea, hot, leaf, green", "Tea, hot, herbal"],
        "black tea": ["Tea, hot, leaf, black"],
        "green tea": ["Tea, hot, leaf, green"],
        "wine": ["Wine, table, red", "Wine, table, white"],
        "zucchini": ["Squash, summer, zucchini, includes skin, raw"],
        "bell pepper": ["Pepper, sweet, green, raw", "Pepper, sweet, red, raw"],
        "bell peppers": ["Pepper, sweet, green, raw", "Pepper, sweet, red, raw"],
        "chips": ["Potato chips, NFS", "Tortilla chips, plain"],
        "taco": ["Taco or tostada with meat"],
        "tacos": ["Taco or tostada with meat"],
        "spaghetti": ["Pasta, cooked"],
        "mac and cheese": ["Macaroni or noodles with cheese"],
        "macaroni and cheese": ["Macaroni or noodles with cheese"],
        "mac n cheese": ["Macaroni or noodles with cheese"],
        "meatloaf": ["Meat loaf made with beef"],
        "pot roast": ["Beef, pot roast, braised or boiled, NS as to fat eaten"],
        "pop tart": ["Toaster pastries, fruit (includes apple, blueberry, cherry, strawberry)"],
        "pop tarts": ["Toaster pastries, fruit (includes apple, blueberry, cherry, strawberry)"],
        "oatmeal": ["Oatmeal, regular or quick, made with water, no added fat"],
        "rotisserie chicken": ["Chicken, NS as to part, rotisserie, skin eaten"],
        "sirloin": ["Beef, top sirloin, steak, separable lean only, trimmed to 0\" fat, all grades, cooked, broiled"],
        "sirloin steak": ["Beef, top sirloin, steak, separable lean only, trimmed to 0\" fat, all grades, cooked, broiled"],
    ]

    // Keyed the way a search is tokenized, so "2 slices toast" and "Mac & Cheese" still match.
    private static let lookup: [String: [String]] = Dictionary(
        leadingEntries.map { (key(for: $0.key), $0.value) },
        uniquingKeysWith: { first, _ in first }
    )

    static func key(for query: String) -> String {
        FtsQueryGenerator.tokenize(query).map { $0.lowercased() }.joined(separator: " ")
    }

    static func leadingDescriptions(for query: String) -> [String] {
        lookup[key(for: query)] ?? []
    }

    /// The leading entries first, then the usual results, each food once.
    static func withLeads(_ leads: [FdcSearchableFood], before results: [FdcSearchableFood]) -> [FdcSearchableFood] {
        var seenIds = Set<Int>()
        var seenNames = Set<String>()
        return (leads + results).filter {
            seenIds.insert($0.fdcId).inserted && seenNames.insert($0.description.lowercased()).inserted
        }
    }
}
