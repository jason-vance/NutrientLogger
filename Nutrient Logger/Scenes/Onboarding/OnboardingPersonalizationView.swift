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

    let onContinue: () -> Void

    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var userService: UserService

    @State private var diet: NutritionDietPreset = .default
    @State private var concern: NutritionConcern = .default

    private func continueAction() {
        NutritionPersonalizationApplier.standard().apply(diet: diet, concern: concern)
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

                    QuestionCard(title: "My diet", value: diet.label, reflectBack: diet.reflectBack) {
                        Picker("My diet", selection: $diet) {
                            ForEach(NutritionDietPreset.allCases) { preset in
                                Text(preset.label).tag(preset)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    QuestionCard(title: "I care most about", value: concern.label, reflectBack: concern.reflectBack) {
                        Picker("I care most about", selection: $concern) {
                            ForEach(NutritionConcern.allCases) { concern in
                                Text(concern.label).tag(concern)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }

            Button(action: continueAction) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder private func QuestionCard<Options: View>(
        title: String,
        value: String,
        reflectBack: String,
        @ViewBuilder options: () -> Options
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                options()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                )
            }

            Text(reflectBack)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .animation(.easeInOut(duration: 0.2), value: reflectBack)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }

    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        OnboardingPersonalizationView(onContinue: {})
    }
}
