//
//  OnboardingPersonalizationView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Onboarding step that asks two quick questions — the user's diet and their main focus — and uses
/// the answers to reorder the Nutrition tab so the nutrients that matter to them sit up top. Both
/// default to a neutral option, so a user can continue without changing anything.
struct OnboardingPersonalizationView: View {

    // Owned by OnboardingView so the selection survives going back and forth between steps.
    @Binding var diet: NutritionDietPreset
    @Binding var concern: NutritionConcern
    let onContinue: () -> Void

    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var userService: UserService

    private func continueAction() {
        NutritionPersonalizationApplier.standard().apply(diet: diet, concern: concern, replacingExisting: true)
        engagementAnalytics.onboardingPersonalizationSelected(diet: diet.rawValue, concern: concern.rawValue)

        // Persist the answers for later reuse; fire-and-forget so the flow stays snappy.
        var user = userService.currentUser
        user.dietPreset = diet
        user.nutritionConcern = concern
        Task { try? await userService.save(user: user) }

        onContinue()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    Text("Let's tailor it to you")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 32)

                    Text("Two quick taps and we'll put the nutrients that matter most to you at the top of your dashboard.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .padding(.bottom, 32)

                    VStack(spacing: 0) {
                        ChoiceQuestion(
                            title: "How do you eat?",
                            options: NutritionDietPreset.allCases,
                            label: \.label,
                            selection: $diet,
                            note: diet.reflectBack
                        )
                        .padding()
                        Divider().padding(.horizontal)
                        ChoiceQuestion(
                            title: "What matters most to you?",
                            options: NutritionConcern.allCases,
                            label: \.label,
                            selection: $concern,
                            note: concern.reflectBack
                        )
                        .padding()
                    }
                    .inCard(backgroundColor: Color.gray)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .readableContentWidth()

            // Reads back the answers, so the button says what it'll set up.
            LogActionButton(
                title: "Let's see it in action",
                detail: "\(diet.label) · \(concern.label)",
                isEnabled: true,
                action: continueAction
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }

    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        OnboardingPersonalizationView(diet: .constant(.default), concern: .constant(.default), onContinue: {})
    }
}
