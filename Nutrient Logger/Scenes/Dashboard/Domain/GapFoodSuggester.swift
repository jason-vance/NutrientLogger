//
//  GapFoodSuggester.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Reads how much of each nutrient a serving of each `GapFoods.pool` food has (once per launch) and
/// turns a low nutrient into a few foods that would help, measured against the user's own goal.
final class GapFoodSuggester {

    static let shared = GapFoodSuggester()

    private var servingNutrients: [Int: [String: Nutrient]]?
    private let lock = NSLock()

    func suggestions(
        for nutrientId: String,
        user: User,
        rdiLibrary: NutrientRdiLibrary,
        remoteDatabase: RemoteDatabase
    ) -> [GapFoods.Suggestion] {
        guard let rdi = NutrientGoalDefaults.effectiveRdi(for: nutrientId, user: user, rdiLibrary: rdiLibrary),
              rdi.recommendedAmount > 0
        else { return [] }

        // Each food's amount as a share of the goal, converting the goal to the food's unit.
        var shareOfGoal: [Int: Double] = [:]
        for (fdcId, nutrients) in table(remoteDatabase) {
            guard let nutrient = nutrients[nutrientId] else { continue }
            let unit = WeightUnit.unitFrom(nutrient)
            let goal = (unit == rdi.unit) ? rdi : rdi.convertedTo(unit)
            guard goal.recommendedAmount > 0 else { continue }
            shareOfGoal[fdcId] = nutrient.amount / goal.recommendedAmount
        }
        // The upper limit as a share of the goal too. Unset limits are stored as the largest Double.
        let upperLimit = rdi.upperLimit < .greatestFiniteMagnitude ? rdi.upperLimit / rdi.recommendedAmount : nil
        return GapFoods.suggestions(
            amountsPerServing: shareOfGoal,
            goal: 1,
            upperLimit: upperLimit,
            diet: user.dietPreset
        )
    }

    private func table(_ remoteDatabase: RemoteDatabase) -> [Int: [String: Nutrient]] {
        lock.lock()
        defer { lock.unlock() }
        if let servingNutrients { return servingNutrients }

        var table: [Int: [String: Nutrient]] = [:]
        for food in GapFoods.pool {
            guard let item = try? remoteDatabase.getFood(String(food.fdcId)),
                  let serving = try? item.applyingPortion(Portion(name: food.serving, amount: 1, gramWeight: food.grams))
            else { continue }
            let nutrients = serving.nutrientGroups.flatMap(\.nutrients)
            table[food.fdcId] = Dictionary(nutrients.map { ($0.fdcNumber, $0) }, uniquingKeysWith: { first, _ in first })
        }
        servingNutrients = table
        return table
    }
}
