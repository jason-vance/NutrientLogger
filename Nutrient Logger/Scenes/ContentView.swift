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

    @Binding var pendingDeepLink: DeepLink?
    @State private var selectedTab: AppTab = .dashboard
    @State private var isSetup: Bool = false
    @State private var showNotificationPrompt: Bool = false
    @State private var showMarketingFromDeepLink: Bool = false

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

    private func handleDeepLink(_ deepLink: DeepLink) {
        guard isSetup, !showNotificationPrompt else { return }
        selectedTab = deepLink.tab
        if deepLink == .premium {
            showMarketingFromDeepLink = true
        }
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
            .onChange(of: pendingDeepLink) { _, newLink in
                guard let link = newLink else { return }
                handleDeepLink(link)
                pendingDeepLink = nil
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
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent", value: AppTab.dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                NavigationStack {
                    FoodSearchView(onFoodSaved: { foodItem, portion in
                        try FoodSaver.forConsumedFoods(modelContext: modelContext).saveFoodItem(foodItem, portion)

                        DispatchQueue.main.async {
                            dataController.updateDailySummary()
                        }
                    })
                }
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack {
                    UserProfileView()
                }
            }
        }
        .sheet(isPresented: $showMarketingFromDeepLink) {
            MarketingView()
        }
    }

}

#Preview {
    ContentView(pendingDeepLink: .constant(nil))
}
