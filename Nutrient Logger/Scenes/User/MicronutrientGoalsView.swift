//
//  MicronutrientGoalsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/17/26.
//

import SwiftUI
import SwinjectAutoregistration

struct MicronutrientGoalsView: View {

    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var engagementAnalytics: EngagementAnalytics

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var user: User?
    @State private var loadedUser: User?
    @State private var showMarketingView: Bool = false

    @State private var showVitamins: Bool = true
    @State private var showMinerals: Bool = true
    @State private var showFattyAcids: Bool = false
    @State private var showAminoAcids: Bool = false
    @State private var showOther: Bool = false

    private var fieldsForGroup: (String) -> [CustomFood.FormField] {
        { group in CustomFood.formFields.filter { $0.group == group } }
    }

    private func fetchUser() {
        let loaded = userService.currentUser
        self.loadedUser = loaded
        self.user = loaded
        expandSectionsWithGoals()
    }

    private func expandSectionsWithGoals() {
        guard let goals = user?.micronutrientGoals, !goals.isEmpty else { return }
        let hasGoal: (String) -> Bool = { group in
            fieldsForGroup(group).contains { goals[$0.fdcNumber] != nil }
        }
        if hasGoal("Fatty Acids") { showFattyAcids = true }
        if hasGoal("Amino Acids") { showAminoAcids = true }
        if CustomFood.otherFields.contains(where: { goals[$0.fdcNumber] != nil }) {
            showOther = true
        }
    }

    private func saveUser() {
        guard let user else { return }
        guard user != loadedUser else { return }
        loadedUser = user
        Task {
            do {
                try await userService.save(user: user)
            } catch {
                print("Failed to save user: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        List {
            if !subscriptionManager.isSubscribed {
                PremiumBanner()
            }
            CollapsibleSection(title: "Vitamins", isExpanded: $showVitamins) {
                ForEach(fieldsForGroup("Vitamins")) { GoalRow(field: $0) }
            }
            CollapsibleSection(title: "Minerals", isExpanded: $showMinerals) {
                ForEach(fieldsForGroup("Minerals")) { GoalRow(field: $0) }
            }
            CollapsibleSection(title: "Fatty Acids", isExpanded: $showFattyAcids) {
                ForEach(fieldsForGroup("Fatty Acids")) { GoalRow(field: $0) }
            }
            CollapsibleSection(title: "Amino Acids", isExpanded: $showAminoAcids) {
                ForEach(fieldsForGroup("Amino Acids")) { GoalRow(field: $0) }
            }
            CollapsibleSection(title: "Other", isExpanded: $showOther) {
                ForEach(CustomFood.otherFields) { GoalRow(field: $0) }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .listDefaultModifiers()
        .navigationTitle("Micronutrient Goals")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .micronutrientGoals)
        }
    }

    @ViewBuilder private func GoalRow(field: CustomFood.FormField) -> some View {
        let rdi = rdiLibrary.getRdis(field.fdcNumber)?.getRdi(user ?? User())
        let placeholder = rdi.map { "\($0.recommendedAmount.formatted(maxDigits: 0))" } ?? "0"

        HStack {
            Text(field.name)
            Spacer()
            TextField(placeholder, text: goalBinding(for: field.fdcNumber))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .bold()
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: 80)
                .disabled(!subscriptionManager.isSubscribed)
            Text(field.unit)
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
        .listRowDefaultModifiers()
    }

    private func goalBinding(for nutrientId: String) -> Binding<String> {
        Binding(
            get: {
                if let v = user?.micronutrientGoals[nutrientId] {
                    return "\(v.formatted(maxDigits: 0))"
                }
                return ""
            },
            set: { newValue in
                let hadGoal = user?.micronutrientGoals[nutrientId] != nil
                if newValue.isEmpty {
                    user?.micronutrientGoals.removeValue(forKey: nutrientId)
                } else if let d = Double(newValue) {
                    user?.micronutrientGoals[nutrientId] = d
                    if !hadGoal {
                        engagementAnalytics.goalSet(goalName: "micronutrient")
                    }
                }
            }
        )
    }

    @ViewBuilder private func PremiumBanner() -> some View {
        Section {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Premium Feature")
                        .font(.headline)
                    Spacer()
                }
                Text("Subscribe to set custom micronutrient targets for vitamins, minerals, and more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    showMarketingView = true
                } label: {
                    Text("Unlock Premium")
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                                .foregroundStyle(Color.accentColor.gradient)
                        }
                }
            }
            .listRowDefaultModifiers()
        }
    }

    @ViewBuilder private func CollapsibleSection(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> some View
    ) -> some View {
        Section {
            if isExpanded.wrappedValue {
                content()
            }
        } header: {
            Button {
                withAnimation(.snappy) { isExpanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Text(title).listSectionHeader()
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    NavigationStack {
        MicronutrientGoalsView()
    }
    .environmentObject(SubscriptionManager())
}
