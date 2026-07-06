//
//  OnboardingView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI
import SwinjectAutoregistration

struct OnboardingView: View {

    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @Inject private var userService: UserService

    @AppStorage("hasStartedOnboarding") private var hasStartedOnboarding: Bool = false
    @AppStorage("onboardingStartedAt") private var onboardingStartedAt: Double = 0
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications: Bool = false

    @State private var step: Int = 0

    private static let totalSteps = 5

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            step += 1
        }
    }

    private func saveAndComplete(user: User, weightKg: Double?) {
        Task {
            try? await userService.save(user: user)
            if let kg = weightKg {
                let entry = WeightEntry(date: .today, weightKg: kg)
                await MainActor.run { modelContext.insert(entry) }
            }
            await MainActor.run { advance() }
        }
    }

    private func finishOnboarding() {
        hasPromptedForNotifications = true
        onComplete()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ProgressDots(step: step)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            hasStartedOnboarding = true
            if onboardingStartedAt == 0 {
                onboardingStartedAt = Date.now.timeIntervalSince1970
            }
        }
    }

    @ViewBuilder private var stepContent: some View {
        if step == 0 {
            OnboardingHeroView(onContinue: advance)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 1 {
            OnboardingGoalView(onContinue: advance)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 2 {
            OnboardingProfileView(onComplete: saveAndComplete)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else if step == 3 {
            OnboardingNotificationView(onContinue: advance)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else {
            OnboardingPaywallView(onComplete: finishOnboarding)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }

    @ViewBuilder private func ProgressDots(step: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<Self.totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.white : Color.white.opacity(0.3))
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    OnboardingView(onComplete: {})
        .environmentObject(SubscriptionManager(isForScreenshots: true))
}
