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
        .environmentObject(SubscriptionManager())
        .environmentObject(DataController.shared)
        .environmentObject(CustomFoodDatabase.shared)
    }
}
