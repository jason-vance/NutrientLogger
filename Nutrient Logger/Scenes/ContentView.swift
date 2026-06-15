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
    
    @EnvironmentObject private var dataController: DataController

    @State private var isSetup: Bool = false
    @State private var showNotificationPrompt: Bool = false

    @AppStorage("hasLaunchedAppBefore") private var hasLaunchedAppBefore: Bool = false
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications: Bool = false

    private func onScenePhaseChange(old: ScenePhase, new: ScenePhase) {
        switch new {
        case .background, .inactive:
            try? modelContext.save()
            Task(priority: .background) {
                try? await Task.sleep(for: .seconds(0.75))
                WidgetCenter.shared.reloadAllTimelines()
            }
            NotificationCoordinator.reschedule(modelContext: modelContext)
            break
        default:
            break
        }

    }

    private func onSetupComplete() {
        if !hasLaunchedAppBefore {
            // Don't interrupt the very first launch with a permission prompt.
            hasLaunchedAppBefore = true
        } else if !hasPromptedForNotifications {
            showNotificationPrompt = true
        }
    }

    private func onNotificationPromptComplete() {
        hasPromptedForNotifications = true
        showNotificationPrompt = false
        NotificationCoordinator.reschedule(modelContext: modelContext)
    }

    var body: some View {
        AppSetupRouter()
            .animation(.snappy, value: isSetup)
            .animation(.snappy, value: showNotificationPrompt)
            .onChange(of: scenePhase, onScenePhaseChange)
            .onChange(of: isSetup) { _, newIsSetup in
                if newIsSetup {
                    onSetupComplete()
                }
            }
    }

    @ViewBuilder private func AppSetupRouter() -> some View {
        ZStack {
            if isSetup {
                if showNotificationPrompt {
                    NotificationPermissionPromptView(onComplete: onNotificationPromptComplete)
                } else {
                    MainContent()
                }
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
                            dataController.updateDailySummary()
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
