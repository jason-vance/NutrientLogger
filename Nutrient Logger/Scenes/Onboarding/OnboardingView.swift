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

    @Inject private var engagementAnalytics: EngagementAnalytics

    @AppStorage("hasStartedOnboarding") private var hasStartedOnboarding: Bool = false
    @AppStorage("onboardingStartedAt") private var onboardingStartedAt: Double = 0
    @AppStorage("onboardingCompletedAt") private var onboardingCompletedAt: Double = 0
    @AppStorage("hasPromptedForNotifications") private var hasPromptedForNotifications: Bool = false

    @State private var step: Int = 0
    @State private var navigatingBackward = false

    private static let totalSteps = 3
    private static let stepNames = ["hero", "notification", "paywall"]

    private func trackStepViewed(_ step: Int) {
        guard Self.stepNames.indices.contains(step) else { return }
        engagementAnalytics.onboardingStepViewed(stepName: Self.stepNames[step], stepIndex: step)
    }

    private func advance() {
        navigatingBackward = false
        withAnimation(.easeInOut(duration: 0.3)) {
            step += 1
        }
    }

    private func goBack() {
        navigatingBackward = true
        withAnimation(.easeInOut(duration: 0.3)) {
            step -= 1
        }
    }

    private var stepTransition: AnyTransition {
        navigatingBackward
            ? .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
            : .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    }

    private func finishOnboarding() {
        hasPromptedForNotifications = true
        onboardingCompletedAt = Date.now.timeIntervalSince1970
        engagementAnalytics.onboardingCompleted()
        onComplete()
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    ProgressDots(step: step)

                    HStack {
                        if step > 0 {
                            Button(action: goBack) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .padding(8)
                            }
                            .transition(.opacity)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .padding(.horizontal, 8)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            hasStartedOnboarding = true
            if onboardingStartedAt == 0 {
                onboardingStartedAt = Date.now.timeIntervalSince1970
            }
            trackStepViewed(step)
        }
        .onChange(of: step) { _, newStep in
            trackStepViewed(newStep)
        }
    }

    @ViewBuilder private var stepContent: some View {
        if step == 0 {
            OnboardingHeroView(onContinue: advance)
                .transition(stepTransition)
        } else if step == 1 {
            OnboardingNotificationView(onContinue: advance)
                .transition(stepTransition)
        } else {
            OnboardingPaywallView(onComplete: finishOnboarding)
                .transition(stepTransition)
        }
    }

    @ViewBuilder private func ProgressDots(step: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<Self.totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    OnboardingView(onComplete: {})
        .environmentObject(SubscriptionManager(isForScreenshots: true))
}
