//
//  ScreenshotScene.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// Opens a screen that normally takes setup, for App Store screenshots. Only in screenshot mode:
///
///     -screenshots -screenshotScene firstDayRecap -screenshotDiet carnivore
///     -screenshots -screenshotScene personalize -screenshotDiet carnivore
///     -screenshots -screenshotScene foodDetails
///     -screenshots -screenshotScene logMeal
///     -screenshots -screenshotScene customFood
///     -screenshots -screenshotScene editMeal
///     -screenshots -screenshotScene logWeight
///
/// `firstDayRecap` shows the recap for the diet's onboarding demo day. `personalize` shows the
/// onboarding diet question with the diet picked. The diet defaults to carnivore. `foodDetails`
/// and `logMeal` push the logging screens for a sample food and a sample saved meal.
enum ScreenshotScene: String {
    case firstDayRecap
    case personalize
    case foodDetails
    case logMeal
    case customFood
    case editMeal
    case logWeight

    /// "Soft drink, cola, diet", a food with several portion sizes.
    static let sampleFoodFdcId = 1104312

    static var current: ScreenshotScene? {
        guard DataController.isScreenshots else { return nil }
        return UserDefaults.standard.string(forKey: "screenshotScene").flatMap(ScreenshotScene.init(rawValue:))
    }

    static var diet: NutritionDietPreset? {
        guard DataController.isScreenshots else { return nil }
        return UserDefaults.standard.string(forKey: "screenshotDiet").flatMap(NutritionDietPreset.init(rawValue:))
    }

    /// The diet's demo day as logged foods for today.
    static var demoDayFoods: [ConsumedFood] {
        (diet ?? .carnivore).demoDay.map {
            ConsumedFood(
                fdcId: $0.fdcId,
                name: "",
                portionAmount: 1,
                portionGramWeight: $0.gramWeight,
                portionName: "serving",
                dateLogged: .today,
                mealTime: $0.mealTime
            )
        }
    }
}
