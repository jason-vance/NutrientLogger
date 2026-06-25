//
//  Nutrient_LoggerApp.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData

//TODO: Maybe add MediaView to native ads (like in Dipply)
//TODO: Add colors for background, text, and accent
@main
struct Nutrient_LoggerApp: App {

    @State private var pendingDeepLink: DeepLink?

    init() {
        if DataController.isScreenshots {
            UserDefaults.standard.set(true, forKey: "hasLaunchedAppBefore")
            UserDefaults.standard.set(true, forKey: "hasPromptedForNotifications")
            UserDefaults.standard.set(false, forKey: HealthKitManager.healthSyncEnabledKey)
            UserDefaults.standard.set(72.57, forKey: "weightGoalKg")
            UserDefaults.standard.set(18.0, forKey: "bodyFatGoalPercentage")
        }

        DataController.shared.onNutrientsUpdated = { nutrientTotals, date in
            Task {
                await HealthKitManager.shared.syncNutrients(nutrientTotals, date: date)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(pendingDeepLink: $pendingDeepLink)
                .onOpenURL { url in
                    pendingDeepLink = DeepLink(url: url)
                }
        }
        .modelContainer(DataController.shared.container)
        .environmentObject(AdProviderFactory.forProd)
        .environmentObject(SubscriptionManager(isForScreenshots: DataController.isScreenshots))
        .environmentObject(DataController.shared)
        .environmentObject(CustomFoodDatabase.shared)
    }
}
