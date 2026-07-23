//
//  OnboardingDemoDay.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// A single food in the onboarding demo dashboard: a real bundled-FDC food id and the serving
/// weight to scale it to. Fetched from the live database so the demo shows genuine nutrient values
/// (including the gaps a diet tends to have).
struct OnboardingDemoFood {
    let fdcId: Int
    let gramWeight: Double
}

extension NutritionDietPreset {

    /// A realistic day of eating that fits the diet, used to populate the onboarding demo dashboard.
    /// Foods are chosen so the diet's promoted "gap" nutrients read low — that low number is the
    /// value demonstration. All ids are verified present in the bundled survey database.
    var demoDay: [OnboardingDemoFood] {
        switch self {
        case .balanced:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1100741, gramWeight: 56),  // Whole wheat toast
                OnboardingDemoFood(fdcId: 1102613, gramWeight: 248), // Orange juice
                OnboardingDemoFood(fdcId: 1098445, gramWeight: 120), // Chicken breast
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 196), // Brown rice
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 155), // Broccoli
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170), // Salmon
            ]
        case .plantBased:
            return [
                OnboardingDemoFood(fdcId: 1101577, gramWeight: 240), // Oatmeal
                OnboardingDemoFood(fdcId: 1102702, gramWeight: 150), // Blueberries
                OnboardingDemoFood(fdcId: 1100507, gramWeight: 28),  // Almonds
                OnboardingDemoFood(fdcId: 1100438, gramWeight: 198), // Lentils
                OnboardingDemoFood(fdcId: 1103116, gramWeight: 67),  // Kale
                OnboardingDemoFood(fdcId: 1100374, gramWeight: 172), // Black beans
                OnboardingDemoFood(fdcId: 1101616, gramWeight: 185), // Quinoa
            ]
        case .ketoLowCarb:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110), // Scrambled eggs
                OnboardingDemoFood(fdcId: 1102652, gramWeight: 100), // Avocado
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170), // Salmon
                OnboardingDemoFood(fdcId: 1103861, gramWeight: 14),  // Olive oil
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 150), // Ground beef
                OnboardingDemoFood(fdcId: 1098007, gramWeight: 28),  // Cheddar cheese
            ]
        case .carnivore:
            return [
                OnboardingDemoFood(fdcId: 1100236, gramWeight: 110), // Scrambled eggs (with butter)
                OnboardingDemoFood(fdcId: 1098175, gramWeight: 170), // Beef steak
                OnboardingDemoFood(fdcId: 1098213, gramWeight: 150), // Ground beef
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 140), // Salmon
            ]
        case .pescatarian:
            return [
                OnboardingDemoFood(fdcId: 1097562, gramWeight: 170), // Greek yogurt
                OnboardingDemoFood(fdcId: 1102653, gramWeight: 126), // Banana
                OnboardingDemoFood(fdcId: 1099030, gramWeight: 140), // Tuna
                OnboardingDemoFood(fdcId: 1101626, gramWeight: 196), // Brown rice
                OnboardingDemoFood(fdcId: 1098962, gramWeight: 170), // Salmon
                OnboardingDemoFood(fdcId: 1103172, gramWeight: 155), // Broccoli
            ]
        }
    }
}
