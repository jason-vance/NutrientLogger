//
//  ContentView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
    @State private var isSetup: Bool = false
    
    private static func onScenePhaseChange(old: ScenePhase, new: ScenePhase) {
        switch new {
        case .background, .inactive:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                WidgetCenter.shared.reloadAllTimelines()
            }
            break
        default:
            break
        }
        
    }
    
    var body: some View {
        AppSetupRouter()
            .animation(.snappy, value: isSetup)
            .onChange(of: scenePhase, Self.onScenePhaseChange)
    }
    
    @ViewBuilder private func AppSetupRouter() -> some View {
        ZStack {
            if isSetup {
                MainContent()
            } else {
                AppSetupView(isSetup: $isSetup)
            }
        }
    }
    
    @ViewBuilder private func MainContent() -> some View {
        TabView {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent") {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    FoodSearchView(onFoodSaved: { foodItem, portion in
                        try FoodSaver.forConsumedFoods(modelContext: modelContext).saveFoodItem(foodItem, portion)
                        
                        DispatchQueue.main.async {
                            DataController.shared.updateDailySummary()
                        }
                    })
                }
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack {
                    UserProfileView()
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
