//
//  ScreenshotScene.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation
import SwiftUI

/// Opens a screen that normally takes setup, for App Store screenshots. Only in screenshot mode:
///
///     -screenshots -screenshotScene firstDayRecap -screenshotDiet carnivore
///     -screenshots -screenshotScene personalize -screenshotDiet carnivore
///     -screenshots -screenshotScene foodBreakdown -screenshotDiet carnivore
///     -screenshots -screenshotScene foodDetails
///     -screenshots -screenshotScene logMeal
///     -screenshots -screenshotScene customFood
///     -screenshots -screenshotScene editMeal
///     -screenshots -screenshotScene logWeight
///     -screenshots -screenshotScene weeklyWatch
///     -screenshots -screenshotScene vitamins
///     -screenshots -screenshotScene body
///     -screenshots -screenshotScene profile
///     -screenshots -screenshotScene nutritionSettings
///     -screenshots -screenshotScene nutrientLibrary
///     -screenshots -screenshotScene search
///
/// `firstDayRecap` shows the recap for the diet's onboarding demo day. `personalize` shows the
/// onboarding diet question with the diet picked. The diet defaults to carnivore. `foodDetails`
/// and `logMeal` push the logging screens for a sample food and a sample saved meal.
/// `weeklyWatch` and `vitamins` scroll the dashboard to that card, `profile` scrolls to the
/// Apple Health row, and `body` and `profile` open those tabs.
enum ScreenshotScene: String {
    case firstDayRecap
    case personalize
    case foodBreakdown
    case foodDetails
    case logMeal
    case customFood
    case editMeal
    case logWeight
    case weeklyWatch
    case vitamins
    case body
    case profile
    case nutritionSettings
    case nutrientLibrary
    case search

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

    /// Scroll ids for the scenes that show a card further down a screen.
    static let weeklyWatchId = "screenshot.weeklyWatch"
    static let vitaminsId = "screenshot.vitamins"
    static let profileDataId = "screenshot.profileData"

    private var scrollTarget: String? {
        switch self {
        case .weeklyWatch: Self.weeklyWatchId
        case .vitamins: Self.vitaminsId
        case .profile: Self.profileDataId
        default: nil
        }
    }

    /// Scrolls to the current scene's card, if it has one, once the screen has loaded its data.
    @MainActor static func scrollIfNeeded(_ proxy: ScrollViewProxy) async {
        guard let target = current?.scrollTarget else { return }
        try? await Task.sleep(for: .seconds(1.5))
        proxy.scrollTo(target, anchor: .top)
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
