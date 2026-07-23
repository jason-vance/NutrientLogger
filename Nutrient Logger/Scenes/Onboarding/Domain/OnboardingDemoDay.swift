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
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110, mealTime: .breakfast), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1100741, gramWeight: 56, mealTime: .breakfast),  // Whole wheat toast
                OnboardingDemoFood(fdcId: 1102613, gramWeight: 248, mealTime: .breakfast), // Orange juice
                OnboardingDemoFood(fdcId: 1098445, gramWeight: 120, mealTime: .lunch),     // Chicken breast
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 196, mealTime: .lunch),     // Brown rice
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 155, mealTime: .lunch),     // Broccoli
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170, mealTime: .dinner),    // Salmon
            ]
        case .plantBased:
            return [
                OnboardingDemoFood(fdcId: 1101577, gramWeight: 240, mealTime: .breakfast), // Oatmeal
                OnboardingDemoFood(fdcId: 1102702, gramWeight: 150, mealTime: .breakfast), // Blueberries
                OnboardingDemoFood(fdcId: 1100507, gramWeight: 28, mealTime: .breakfast),  // Almonds
                OnboardingDemoFood(fdcId: 1100438, gramWeight: 198, mealTime: .lunch),     // Lentils
                OnboardingDemoFood(fdcId: 1103116, gramWeight: 67, mealTime: .lunch),      // Kale
                OnboardingDemoFood(fdcId: 1100374, gramWeight: 172, mealTime: .dinner),    // Black beans
                OnboardingDemoFood(fdcId: 1101616, gramWeight: 185, mealTime: .dinner),    // Quinoa
            ]
        case .ketoLowCarb:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110, mealTime: .breakfast), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1102652, gramWeight: 100, mealTime: .breakfast), // Avocado
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170, mealTime: .lunch),     // Salmon
                OnboardingDemoFood(fdcId: 1103861, gramWeight: 14, mealTime: .lunch),      // Olive oil
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 150, mealTime: .dinner),    // Ground beef
                OnboardingDemoFood(fdcId: 1098007, gramWeight: 28, mealTime: .dinner),     // Cheddar cheese
            ]
        case .carnivore:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110, mealTime: .breakfast), // Scrambled eggs (with butter)
                OnboardingDemoFood(fdcId: 1098175, gramWeight: 170, mealTime: .lunch),     // Beef steak
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 150, mealTime: .dinner),    // Ground beef
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 140, mealTime: .dinner),    // Salmon
            ]
        case .pescatarian:
            return [
                OnboardingDemoFood(fdcId: 1097562, gramWeight: 170, mealTime: .breakfast), // Greek yogurt
                OnboardingDemoFood(fdcId: 1102653, gramWeight: 126, mealTime: .breakfast), // Banana
                OnboardingDemoFood(fdcId: 1099030, gramWeight: 140, mealTime: .lunch),     // Tuna
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 196, mealTime: .lunch),     // Brown rice
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170, mealTime: .dinner),    // Salmon
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 155, mealTime: .dinner),    // Broccoli
            ]
        }
    }
}
