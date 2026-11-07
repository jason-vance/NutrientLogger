//
//  OnboardingDemoDay.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// A single food in the onboarding demo dashboard: a real bundled-FDC food id, the serving weight
/// to scale it to, and the meal it belongs to. Fetched from the live database so the demo shows
/// genuine nutrient values (including the gaps a diet tends to have).
struct OnboardingDemoFood {
    let fdcId: Int
    let gramWeight: Double
    let mealTime: MealTime
}

extension NutritionDietPreset {

    /// A realistic day of eating that fits the diet, used to populate the onboarding demo dashboard.
    /// Foods are chosen so the diet's promoted "gap" nutrients read low — that low number is the
    /// value demonstration. All ids are verified present in the bundled survey database.
    var demoDay: [OnboardingDemoFood] {
        switch self {
        case .balanced:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 150, mealTime: .breakfast), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1100741, gramWeight: 90, mealTime: .breakfast),  // Whole wheat toast
                OnboardingDemoFood(fdcId: 1102613, gramWeight: 250, mealTime: .breakfast), // Orange juice
                OnboardingDemoFood(fdcId: 1098445, gramWeight: 240, mealTime: .lunch),     // Chicken breast
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 340, mealTime: .lunch),     // Brown rice
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 160, mealTime: .lunch),     // Broccoli
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 240, mealTime: .dinner),    // Salmon
            ]
        case .plantBased:
            return [
                OnboardingDemoFood(fdcId: 1101577, gramWeight: 350, mealTime: .breakfast), // Oatmeal
                OnboardingDemoFood(fdcId: 1102702, gramWeight: 200, mealTime: .breakfast), // Blueberries
                OnboardingDemoFood(fdcId: 1100507, gramWeight: 50, mealTime: .breakfast),  // Almonds
                OnboardingDemoFood(fdcId: 1100438, gramWeight: 300, mealTime: .lunch),     // Lentils
                OnboardingDemoFood(fdcId: 1103116, gramWeight: 100, mealTime: .lunch),     // Kale
                OnboardingDemoFood(fdcId: 1100374, gramWeight: 220, mealTime: .dinner),    // Black beans
                OnboardingDemoFood(fdcId: 1101616, gramWeight: 280, mealTime: .dinner),    // Quinoa
            ]
        case .ketoLowCarb:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 165, mealTime: .breakfast), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1102652, gramWeight: 170, mealTime: .breakfast), // Avocado
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 220, mealTime: .lunch),     // Salmon
                OnboardingDemoFood(fdcId: 1103861, gramWeight: 22, mealTime: .lunch),      // Olive oil
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 220, mealTime: .dinner),    // Ground beef
                OnboardingDemoFood(fdcId: 1098007, gramWeight: 50, mealTime: .dinner),     // Cheddar cheese
            ]
        case .carnivore:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 165, mealTime: .breakfast), // Scrambled eggs (with butter)
                OnboardingDemoFood(fdcId: 1098175, gramWeight: 300, mealTime: .lunch),     // Beef steak
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 250, mealTime: .dinner),    // Ground beef
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 240, mealTime: .dinner),    // Salmon
            ]
        case .paleo:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 150, mealTime: .breakfast), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1102702, gramWeight: 150, mealTime: .breakfast), // Blueberries
                OnboardingDemoFood(fdcId: 1098445, gramWeight: 200, mealTime: .lunch),     // Chicken breast
                OnboardingDemoFood(fdcId: 1103235, gramWeight: 200, mealTime: .lunch),     // Sweet potato
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 150, mealTime: .lunch),     // Broccoli
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 220, mealTime: .dinner),    // Ground beef
                OnboardingDemoFood(fdcId: 1102652, gramWeight: 100, mealTime: .dinner),    // Avocado
                OnboardingDemoFood(fdcId: 1100507, gramWeight: 30, mealTime: .lunch),      // Almonds
            ]
        case .pescatarian:
            return [
                OnboardingDemoFood(fdcId: 1097562, gramWeight: 250, mealTime: .breakfast), // Greek yogurt
                OnboardingDemoFood(fdcId: 1102653, gramWeight: 160, mealTime: .breakfast), // Banana
                OnboardingDemoFood(fdcId: 1099030, gramWeight: 260, mealTime: .lunch),     // Tuna
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 480, mealTime: .lunch),     // Brown rice
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 320, mealTime: .dinner),    // Salmon
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 180, mealTime: .dinner),    // Broccoli
            ]
        }
    }
}

/// A food offered on the onboarding "tap a food" step, with a short name and everyday serving.
struct OnboardingBreakdownFood: Identifiable, Hashable {
    let fdcId: Int
    let gramWeight: Double
    let name: String
    let serving: String

    var id: Int { fdcId }
}

extension NutritionDietPreset {

    /// Four familiar foods that fit the diet, all from its demo day so their ids are known to be in
    /// the bundled database.
    var breakdownFoods: [OnboardingBreakdownFood] {
        let eggs = OnboardingBreakdownFood(fdcId: 1100236, gramWeight: 150, name: "Eggs", serving: "3 scrambled")
        let steak = OnboardingBreakdownFood(fdcId: 1098175, gramWeight: 227, name: "Steak", serving: "8 oz")
        let groundBeef = OnboardingBreakdownFood(fdcId: 1098213, gramWeight: 170, name: "Ground beef", serving: "6 oz")
        let salmon = OnboardingBreakdownFood(fdcId: 1098962, gramWeight: 170, name: "Salmon", serving: "6 oz")
        let chicken = OnboardingBreakdownFood(fdcId: 1098445, gramWeight: 170, name: "Chicken breast", serving: "6 oz")
        let broccoli = OnboardingBreakdownFood(fdcId: 1103172, gramWeight: 160, name: "Broccoli", serving: "1 cup")
        let avocado = OnboardingBreakdownFood(fdcId: 1102652, gramWeight: 150, name: "Avocado", serving: "1 whole")
        let cheddar = OnboardingBreakdownFood(fdcId: 1098007, gramWeight: 56, name: "Cheddar", serving: "2 oz")
        let sweetPotato = OnboardingBreakdownFood(fdcId: 1103235, gramWeight: 200, name: "Sweet potato", serving: "1 medium")
        let blueberries = OnboardingBreakdownFood(fdcId: 1102702, gramWeight: 150, name: "Blueberries", serving: "1 cup")
        let oatmeal = OnboardingBreakdownFood(fdcId: 1101577, gramWeight: 234, name: "Oatmeal", serving: "1 cup")
        let lentils = OnboardingBreakdownFood(fdcId: 1100438, gramWeight: 198, name: "Lentils", serving: "1 cup")
        let kale = OnboardingBreakdownFood(fdcId: 1103116, gramWeight: 130, name: "Kale", serving: "1 cup cooked")
        let almonds = OnboardingBreakdownFood(fdcId: 1100507, gramWeight: 28, name: "Almonds", serving: "1 oz")
        let tuna = OnboardingBreakdownFood(fdcId: 1099030, gramWeight: 165, name: "Tuna", serving: "1 can")
        let yogurt = OnboardingBreakdownFood(fdcId: 1097562, gramWeight: 200, name: "Greek yogurt", serving: "1 cup")

        switch self {
        case .balanced: return [eggs, chicken, salmon, broccoli]
        case .plantBased: return [oatmeal, lentils, kale, almonds]
        case .ketoLowCarb: return [eggs, avocado, salmon, cheddar]
        case .carnivore: return [steak, eggs, salmon, groundBeef]
        case .paleo: return [eggs, sweetPotato, chicken, blueberries]
        case .pescatarian: return [salmon, tuna, yogurt, broccoli]
        }
    }

    /// The vitamin and mineral gaps this diet usually has, for flagging what a food leaves out.
    var micronutrientGaps: [String] {
        (promotedNutrients[.vitamins] ?? []) + (promotedNutrients[.minerals] ?? [])
    }
}
