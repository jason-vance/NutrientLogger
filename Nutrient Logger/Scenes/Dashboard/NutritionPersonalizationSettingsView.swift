//
//  NutritionPersonalizationSettingsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Lets an existing/returning user set or change their diet & focus after onboarding — the same two
/// questions the onboarding personalization step asks — and re-apply the Nutrition-tab ordering.
/// Onboarding only runs once, so this is how users who installed before personalization (or who
/// simply changed their mind) get tailored. Reuses `NutritionPersonalizationApplier`: it applies
/// without clobbering a group the user has already arranged by hand, unless they explicitly choose to
/// reset that group to the suggested order.
struct NutritionPersonalizationSettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics

    @State private var diet: NutritionDietPreset = .default
    @State private var concern: NutritionConcern = .default
    @State private var didLoad = false
    @State private var showResetConfirmation = false

    /// True when at least one group already has a hand-arranged order that a non-clobbering apply
    /// would leave untouched. Drives whether we need to offer the explicit "reset to suggested" path.
    private var hasExistingCustomization: Bool {
        CustomizableNutrientGroup.allCases.contains { group in
            !(UserDefaults.standard.string(forKey: group.orderStorageKey) ?? "").isEmpty
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        let user = userService.currentUser
        diet = user.dietPreset ?? .default
        concern = user.nutritionConcern ?? .default
    }

    private func apply(replacingExisting: Bool) {
        NutritionPersonalizationApplier.standard()
            .apply(diet: diet, concern: concern, replacingExisting: replacingExisting)
        engagementAnalytics.settingsPersonalizationUpdated(diet: diet.rawValue, concern: concern.rawValue)

        var user = userService.currentUser
        user.dietPreset = diet
        user.nutritionConcern = concern
        Task { try? await userService.save(user: user) }

        dismiss()
    }

    private func applyTapped() {
        // Nothing to protect: apply straight to the top of every promoted group.
        if !hasExistingCustomization {
            apply(replacingExisting: true)
        } else {
            // Fill only the groups the user hasn't arranged themselves; anything already customized
            // stays put unless they opt into the reset below.
            apply(replacingExisting: false)
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Diet", selection: $diet) {
                    ForEach(NutritionDietPreset.allCases) { preset in
                        Text(preset.label).tag(preset)
                    }
                }
                Picker("Focus", selection: $concern) {
                    ForEach(NutritionConcern.allCases) { concern in
                        Text(concern.label).tag(concern)
                    }
                }
            } header: {
                Text("Diet & Focus")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    ReflectBackLine(diet.reflectBack)
                    ReflectBackLine(concern.reflectBack)
                }
                .animation(.easeInOut(duration: 0.2), value: diet)
                .animation(.easeInOut(duration: 0.2), value: concern)
            }

            Section {
                Button {
                    applyTapped()
                } label: {
                    Text("Apply to My Dashboard")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            } footer: {
                Text(hasExistingCustomization
                     ? "We'll move these nutrients to the top of any group you haven't arranged yourself. Use \u{201C}Reset\u{201D} below to also re-sort groups you've customized."
                     : "We'll move the nutrients that matter most to you to the top of your Nutrition tab.")
            }

            if hasExistingCustomization {
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset to Suggested Order")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Personalize")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadIfNeeded)
        .confirmationDialog(
            "Reset to suggested order?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Suggested Order", role: .destructive) {
                apply(replacingExisting: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces your current nutrient arrangement with the suggested order for your diet and focus.")
        }
    }
}

/// One reflect-back line under the pickers, prefixed with a small accent bullet so the two read as a
/// short list.
private struct ReflectBackLine: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundStyle(Color.accentColor)
            Text(text)
        }
    }
}

#Preview("No customization") {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        NutritionPersonalizationSettingsView()
    }
}
