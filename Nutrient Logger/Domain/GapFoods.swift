//
//  GapFoods.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Everyday foods to suggest when a nutrient runs low ("Magnesium: try pumpkin seeds, spinach or
/// almonds"). Ranking every USDA food by amount puts spices and powders first, so suggestions come
/// from this short list of foods people actually eat, at a normal serving, filtered to the user's
/// diet (a carnivore never gets told to eat spinach).
enum GapFoods {

    enum Kind: CaseIterable {
        case meat, organ, seafood, egg, dairy, milk
        case vegetable, starchyVegetable, fruit, berry, avocado
        case legume, soy, grain, nut, seed, oil
    }

    struct Food: Equatable {
        let fdcId: Int
        /// Short name for use mid-sentence: "beef liver".
        let name: String
        /// Normal serving, shown next to the name: "3 oz".
        let serving: String
        let grams: Double
        let kind: Kind

        /// "beef liver (3 oz)"
        var label: String { "\(name) (\(serving))" }
    }

    struct Suggestion: Equatable {
        let food: Food
        /// Share of the daily goal one serving gives, e.g. 0.4 for 40%.
        let percentOfGoal: Double
    }

    static let maxSuggestions = 3
    /// A serving has to give at least this much of the goal to be worth suggesting.
    static let minimumPercentOfGoal = 0.1

    static func allowedKinds(for diet: NutritionDietPreset?) -> Set<Kind> {
        let animal: Set<Kind> = [.meat, .organ, .seafood, .egg, .dairy, .milk]
        let plants: Set<Kind> = [.vegetable, .starchyVegetable, .fruit, .berry, .avocado, .legume, .soy, .grain, .nut, .seed, .oil]
        switch diet ?? .balanced {
        case .balanced: return Set(Kind.allCases)
        case .plantBased: return plants
        case .carnivore: return animal
        case .ketoLowCarb: return [.meat, .organ, .seafood, .egg, .dairy, .vegetable, .berry, .avocado, .nut, .seed, .oil]
        case .paleo: return [.meat, .organ, .seafood, .egg, .vegetable, .starchyVegetable, .fruit, .berry, .avocado, .nut, .seed, .oil]
        case .pescatarian: return Set(Kind.allCases).subtracting([.meat, .organ])
        }
    }

    /// The best foods for one nutrient. `amountsPerServing` maps a food's fdcId to how much of the
    /// nutrient one serving has, in the same unit as `goal` and `upperLimit`. A food whose serving
    /// alone goes over the upper limit is left out (3 oz of beef liver is almost 9 days of vitamin A).
    static func suggestions(
        amountsPerServing: [Int: Double],
        goal: Double,
        upperLimit: Double? = nil,
        diet: NutritionDietPreset?,
        foods: [Food] = pool
    ) -> [Suggestion] {
        guard goal > 0 else { return [] }
        let allowed = allowedKinds(for: diet)
        let ranked = foods
            .filter { allowed.contains($0.kind) }
            .compactMap { food -> Suggestion? in
                guard let amount = amountsPerServing[food.fdcId] else { return nil }
                if let upperLimit, amount > upperLimit { return nil }
                let percent = amount / goal
                return percent >= minimumPercentOfGoal ? Suggestion(food: food, percentOfGoal: percent) : nil
            }
            .sorted { $0.percentOfGoal > $1.percentOfGoal }
        return Array(ranked.prefix(maxSuggestions))
    }

    /// "beef liver (3 oz), oysters (3 oz) or sardines (3 oz)"
    static func sentence(_ suggestions: [Suggestion]) -> String? {
        guard !suggestions.isEmpty else { return nil }
        return FirstDayRecap.naturalList(suggestions.map(\.food.label)).replacingLast(" and ", with: " or ")
    }

    // All ids are in the bundled databases. The survey foods (ids from 1097000) don't record
    // manganese, so the foods richest in it use their older USDA entries instead. Brazil nuts are 2 nuts, not an ounce, because an ounce
    // is over the upper limit for selenium.
    static let pool: [Food] = [
        // Meat and organs
        Food(fdcId: 1098653, name: "beef liver", serving: "3 oz", grams: 85, kind: .organ),
        Food(fdcId: 1098655, name: "chicken liver", serving: "3 oz", grams: 85, kind: .organ),
        Food(fdcId: 1098172, name: "steak", serving: "6 oz", grams: 170, kind: .meat),
        Food(fdcId: 1098213, name: "ground beef", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098445, name: "chicken breast", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098526, name: "chicken thigh", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098247, name: "pork chop", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098343, name: "lamb chop", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098407, name: "bison", serving: "4 oz", grams: 113, kind: .meat),
        Food(fdcId: 1098336, name: "pork rinds", serving: "1 oz", grams: 28, kind: .meat),
        // Seafood
        Food(fdcId: 1098965, name: "salmon", serving: "4 oz", grams: 113, kind: .seafood),
        Food(fdcId: 1098981, name: "sardines", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 1098894, name: "canned mackerel", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 1099042, name: "canned tuna", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 171956, name: "cod", serving: "4 oz", grams: 113, kind: .seafood),
        Food(fdcId: 1099149, name: "shrimp", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 1099132, name: "oysters", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 174217, name: "mussels", serving: "3 oz", grams: 85, kind: .seafood),
        Food(fdcId: 171975, name: "clams", serving: "3 oz", grams: 85, kind: .seafood),
        // Eggs and dairy
        Food(fdcId: 1100185, name: "eggs", serving: "2", grams: 100, kind: .egg),
        Food(fdcId: 1098007, name: "cheddar", serving: "1 oz", grams: 28, kind: .dairy),
        Food(fdcId: 1098033, name: "Swiss cheese", serving: "1 oz", grams: 28, kind: .dairy),
        Food(fdcId: 1098021, name: "mozzarella", serving: "1 oz", grams: 28, kind: .dairy),
        Food(fdcId: 1097562, name: "Greek yogurt", serving: "1 cup", grams: 227, kind: .dairy),
        Food(fdcId: 172179, name: "cottage cheese", serving: "1 cup", grams: 210, kind: .dairy),
        Food(fdcId: 1103822, name: "butter", serving: "1 tbsp", grams: 14, kind: .dairy),
        Food(fdcId: 1097512, name: "milk", serving: "1 cup", grams: 244, kind: .milk),
        // Vegetables
        Food(fdcId: 168463, name: "cooked spinach", serving: "1 cup", grams: 180, kind: .vegetable),
        Food(fdcId: 1103120, name: "cooked kale", serving: "1 cup", grams: 130, kind: .vegetable),
        Food(fdcId: 1103092, name: "cooked collards", serving: "1 cup", grams: 190, kind: .vegetable),
        Food(fdcId: 1103172, name: "broccoli", serving: "1 cup", grams: 156, kind: .vegetable),
        Food(fdcId: 1103467, name: "Brussels sprouts", serving: "1 cup", grams: 156, kind: .vegetable),
        Food(fdcId: 1103421, name: "asparagus", serving: "1 cup", grams: 180, kind: .vegetable),
        Food(fdcId: 1103372, name: "red bell pepper", serving: "1", grams: 119, kind: .vegetable),
        Food(fdcId: 1103276, name: "tomato", serving: "1", grams: 123, kind: .vegetable),
        Food(fdcId: 1103193, name: "carrot", serving: "1", grams: 61, kind: .vegetable),
        Food(fdcId: 1103345, name: "cauliflower", serving: "1 cup", grams: 107, kind: .vegetable),
        Food(fdcId: 1103362, name: "mushrooms", serving: "1 cup", grams: 70, kind: .vegetable),
        Food(fdcId: 1103235, name: "sweet potato", serving: "1", grams: 114, kind: .starchyVegetable),
        Food(fdcId: 1103024, name: "baked potato", serving: "1", grams: 173, kind: .starchyVegetable),
        // Fruit
        Food(fdcId: 1102652, name: "avocado", serving: "½", grams: 100, kind: .avocado),
        Food(fdcId: 1102653, name: "banana", serving: "1", grams: 118, kind: .fruit),
        Food(fdcId: 1102597, name: "orange", serving: "1", grams: 131, kind: .fruit),
        Food(fdcId: 1102667, name: "kiwis", serving: "2", grams: 150, kind: .fruit),
        Food(fdcId: 1102670, name: "mango", serving: "1 cup", grams: 165, kind: .fruit),
        Food(fdcId: 1102674, name: "papaya", serving: "1 cup", grams: 145, kind: .fruit),
        Food(fdcId: 1102655, name: "cantaloupe", serving: "1 cup", grams: 160, kind: .fruit),
        Food(fdcId: 169124, name: "pineapple", serving: "1 cup", grams: 165, kind: .fruit),
        Food(fdcId: 1102710, name: "strawberries", serving: "1 cup", grams: 152, kind: .berry),
        Food(fdcId: 167755, name: "raspberries", serving: "1 cup", grams: 123, kind: .berry),
        Food(fdcId: 1102700, name: "blackberries", serving: "1 cup", grams: 144, kind: .berry),
        Food(fdcId: 1102702, name: "blueberries", serving: "1 cup", grams: 148, kind: .berry),
        // Beans, soy and grains
        Food(fdcId: 1100374, name: "black beans", serving: "1 cup", grams: 172, kind: .legume),
        Food(fdcId: 1100438, name: "lentils", serving: "1 cup", grams: 198, kind: .legume),
        Food(fdcId: 173757, name: "chickpeas", serving: "1 cup", grams: 164, kind: .legume),
        Food(fdcId: 1100394, name: "kidney beans", serving: "1 cup", grams: 177, kind: .legume),
        Food(fdcId: 1100534, name: "peanuts", serving: "1 oz", grams: 28, kind: .legume),
        Food(fdcId: 172475, name: "firm tofu", serving: "½ cup", grams: 126, kind: .soy),
        Food(fdcId: 1100450, name: "edamame", serving: "1 cup", grams: 155, kind: .soy),
        Food(fdcId: 1097542, name: "soy milk", serving: "1 cup", grams: 243, kind: .soy),
        Food(fdcId: 1101580, name: "oatmeal", serving: "1 cup", grams: 234, kind: .grain),
        Food(fdcId: 1101616, name: "quinoa", serving: "1 cup", grams: 185, kind: .grain),
        Food(fdcId: 1101631, name: "brown rice", serving: "1 cup", grams: 195, kind: .grain),
        Food(fdcId: 1100740, name: "whole wheat bread", serving: "2 slices", grams: 64, kind: .grain),
        // Nuts, seeds and oils
        Food(fdcId: 1100507, name: "almonds", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 1100515, name: "cashews", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 1100514, name: "Brazil nuts", serving: "2", grams: 10, kind: .nut),
        Food(fdcId: 1100553, name: "walnuts", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 1100549, name: "pistachios", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 1100525, name: "macadamias", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 170182, name: "pecans", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 170581, name: "hazelnuts", serving: "1 oz", grams: 28, kind: .nut),
        Food(fdcId: 170556, name: "pumpkin seeds", serving: "1 oz", grams: 28, kind: .seed),
        Food(fdcId: 1100607, name: "sunflower seeds", serving: "1 oz", grams: 28, kind: .seed),
        Food(fdcId: 1100612, name: "chia seeds", serving: "2 tbsp", grams: 24, kind: .seed),
        Food(fdcId: 1103861, name: "olive oil", serving: "1 tbsp", grams: 13.5, kind: .oil),
        Food(fdcId: 1103867, name: "sunflower oil", serving: "1 tbsp", grams: 13.6, kind: .oil),
    ]
}

private extension String {
    func replacingLast(_ target: String, with replacement: String) -> String {
        guard let range = range(of: target, options: .backwards) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
}
