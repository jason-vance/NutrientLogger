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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataController.shared.container)
        .environmentObject(AdProviderFactory.forProd)
        .environmentObject(SubscriptionManager())
    }
}
