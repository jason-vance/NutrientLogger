//
//  ContentView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData
import WidgetKit
import SwinjectAutoregistration

struct ContentView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var dataController: DataController

    @Inject private var engagementAnalytics: EngagementAnalytics

    @Binding var pendingDeepLink: DeepLink?
    @State private var selectedTab: AppTab = .dashboard
    @State private var isSetup: Bool = false
    @State private var showNotificationPrompt: Bool = false
    @State private var showMarketingFromDeepLink: Bool = false

    @AppStorage("hasLaunchedAppBefore") private var hasLaunchedAppBefore: Bool = false
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    private static let bodyTabIcons = [
        "figure.run",
        "figure.walk",
        "figure.hiking",
        "figure.strengthtraining.traditional",
        "figure.yoga",
        "figure.pilates",
        "figure.dance",
        "figure.jumprope",
        "figure.kickboxing",
        "figure.outdoor.cycle",
        "figure.pool.swim",
        "figure.cooldown",
        "figure.gymnastics",
        "figure.flexibility",
        "figure.cross.training",
    ]
    @State private var bodyTabIcon: String = bodyTabIcons.randomElement()!

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
            hasLaunchedAppBefore = true
        } else if hasCompletedOnboarding && !hasPromptedForNotifications {
            showNotificationPrompt = true
        }
    }

    private func onOnboardingComplete() {
        withAnimation(.snappy) { hasCompletedOnboarding = true }
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
                if !hasCompletedOnboarding {
                    OnboardingView(onComplete: onOnboardingComplete)
                } else if showNotificationPrompt {
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
            Tab("Nutrition", systemImage: "gauge.with.dots.needle.33percent", value: AppTab.dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Body", systemImage: bodyTabIcon, value: AppTab.body) {
                NavigationStack {
                    WeightTrackingView()
                }
            }
            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack {
                    UserProfileView()
                }
            }
        }
        .onChange(of: selectedTab, initial: true) { _, tab in
            let name: String = switch tab {
            case .dashboard: "Nutrition"
            case .body: "Body"
            case .profile: "Profile"
            }
            engagementAnalytics.screenViewed(screenName: name)
        }
        .sheet(isPresented: $showMarketingFromDeepLink) {
            MarketingView(trigger: .deepLink)
        }
    }

}

#Preview {
    ContentView(pendingDeepLink: .constant(nil))
}
