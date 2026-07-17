//
//  NutrientRatio.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/17/26.
//

import Foundation

/// A "balance" between two nutrients (or two summed groups of nutrients) whose *proportion* to
/// each other matters more than either one's absolute amount — e.g. sodium vs. potassium. A ratio
/// is flagged as out of balance when its value falls outside the healthy band. Framed as a balance,
/// not a hard high/low limit: the point is how the two sit relative to one another.
struct NutrientRatio: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var numeratorLabel: String
    var denominatorLabel: String
    var numeratorNutrientIds: [String]
    var denominatorNutrientIds: [String]
    /// Flag when the ratio rises above this value. nil means no upper bound.
    var healthyMax: Double?
    /// Flag when the ratio falls below this value. nil means no lower bound.
    var healthyMin: Double?
    /// Plain-language "why this balance matters", shown when the user taps the balance.
    var explanation: String
    let isBuiltIn: Bool

    var allNutrientIds: [String] { numeratorNutrientIds + denominatorNutrientIds }

    /// e.g. "Aim for under 1:1", "Aim for at least 1:1", "Aim for 1.5–3:1".
    var targetText: String {
        func fmt(_ value: Double) -> String { value.formatted(maxDigits: 1) }
        switch (healthyMin, healthyMax) {
        case let (min?, max?):
            return "Aim for \(fmt(min))–\(fmt(max)) : 1"
        case let (nil, max?):
            return "Aim for under \(fmt(max)) : 1"
        case let (min?, nil):
            return "Aim for at least \(fmt(min)) : 1"
        case (nil, nil):
            return ""
        }
    }
}

/// The built-in balances shipped as defaults. Tier 1 (strong evidence: Na:K, Zn:Cu) plus tier 2
/// (interesting, weaker evidence: Omega-6:3, Ca:P, Ca:Mg). Users can disable any of these and add
/// their own in Nutrition Settings.
enum NutrientBalanceDefaults {

    static let sodiumPotassiumId = "sodium_potassium"
    static let zincCopperId = "zinc_copper"
    static let omega6Omega3Id = "omega6_omega3"
    static let calciumPhosphorusId = "calcium_phosphorus"
    static let calciumMagnesiumId = "calcium_magnesium"

    static let all: [NutrientRatio] = [
        NutrientRatio(
            id: sodiumPotassiumId,
            name: "Sodium : Potassium",
            numeratorLabel: "Sodium",
            denominatorLabel: "Potassium",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Sodium_Na],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Potassium_K],
            healthyMax: 1.0,
            healthyMin: nil,
            explanation: "Modern diets tend to run high in sodium and low in potassium. Keeping sodium at or below potassium supports healthy blood pressure — the balance matters more than either number alone.",
            isBuiltIn: true
        ),
        NutrientRatio(
            id: zincCopperId,
            name: "Zinc : Copper",
            numeratorLabel: "Zinc",
            denominatorLabel: "Copper",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Copper_Cu],
            healthyMax: 15.0,
            healthyMin: nil,
            explanation: "Too much zinc — usually from supplements — can crowd out copper. Dietary intakes around 8–12 : 1 are normal; much above 15 : 1 can leave you short on copper.",
            isBuiltIn: true
        ),
        NutrientRatio(
            id: omega6Omega3Id,
            name: "Omega-6 : Omega-3",
            numeratorLabel: "Omega-6",
            denominatorLabel: "Omega-3",
            numeratorNutrientIds: [
                FdcNutrientGroupMapper.NutrientNumber_18_2, // Linoleic acid
                FdcNutrientGroupMapper.NutrientNumber_20_4  // Arachidonic acid
            ],
            denominatorNutrientIds: [
                FdcNutrientGroupMapper.NutrientNumber_18_3,       // ALA
                FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA, // EPA
                FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA  // DHA
            ],
            healthyMax: 4.0,
            healthyMin: nil,
            explanation: "Western diets are heavy in omega-6 and light in omega-3. A ratio closer to 4 : 1 or lower is associated with lower inflammation.",
            isBuiltIn: true
        ),
        NutrientRatio(
            id: calciumPhosphorusId,
            name: "Calcium : Phosphorus",
            numeratorLabel: "Calcium",
            denominatorLabel: "Phosphorus",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P],
            healthyMax: nil,
            healthyMin: 0.5,
            explanation: "Lots of processed food and soda pushes phosphorus up relative to calcium. A very low calcium-to-phosphorus ratio can work against bone health.",
            isBuiltIn: true
        ),
        NutrientRatio(
            id: calciumMagnesiumId,
            name: "Calcium : Magnesium",
            numeratorLabel: "Calcium",
            denominatorLabel: "Magnesium",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg],
            healthyMax: 3.0,
            healthyMin: 1.5,
            explanation: "Calcium and magnesium work together. A ratio far from roughly 2 : 1 in either direction may mean one is crowding out the other. (Evidence here is softer than the other balances.)",
            isBuiltIn: true
        )
    ]
}

/// Reads/writes the user's balance customization: which built-in balances are disabled, and any
/// custom balances they've added. Persisted as `@AppStorage` strings (CSV for hidden ids, JSON for
/// custom ratios) so both the dashboard card and the settings screen stay in sync.
enum NutrientBalanceSettings {

    static let hiddenKey = "nutrientBalance_hidden"
    static let customKey = "nutrientBalance_custom"

    static func hiddenIds(from raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    static func encodeHidden(_ ids: Set<String>) -> String {
        ids.sorted().joined(separator: ",")
    }

    static func customRatios(from raw: String) -> [NutrientRatio] {
        guard !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([NutrientRatio].self, from: data)
        else { return [] }
        return decoded
    }

    static func encode(customRatios: [NutrientRatio]) -> String {
        guard let data = try? JSONEncoder().encode(customRatios),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }

    /// Built-in defaults followed by the user's custom balances, each minus anything the user
    /// disabled. Both are filtered by the same hidden set so the enable/disable toggle works
    /// uniformly (custom ids are UUIDs, so they never collide with built-in ids).
    static func effectiveRatios(hiddenRaw: String, customRaw: String) -> [NutrientRatio] {
        let hidden = hiddenIds(from: hiddenRaw)
        let builtIns = NutrientBalanceDefaults.all.filter { !hidden.contains($0.id) }
        let customs = customRatios(from: customRaw).filter { !hidden.contains($0.id) }
        return builtIns + customs
    }
}
