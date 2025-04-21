//
//  Nutrient_LoggerApp.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData

//TODO: MVP: Put ads everywhere appropriate
//TODO: Add colors for background, text, and accent
@main
struct Nutrient_LoggerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ConsumedFood.self,
            FoodSearchView.RecentSearch.self,
            Meal.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
