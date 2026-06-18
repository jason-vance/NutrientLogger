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

    @State private var user: User?

    @State private var showVitamins: Bool = true
    @State private var showMinerals: Bool = true
    @State private var showFattyAcids: Bool = false
    @State private var showAminoAcids: Bool = false
    @State private var showOther: Bool = false

    private var fieldsForGroup: (String) -> [CustomFood.FormField] {
        { group in CustomFood.formFields.filter { $0.group == group } }
    }

    private func fetchUser() {
        self.user = userService.currentUser
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
        .scrollDismissesKeyboard(.interactively)
        .listDefaultModifiers()
        .navigationTitle("Micronutrient Goals")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
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
                if newValue.isEmpty {
                    user?.micronutrientGoals.removeValue(forKey: nutrientId)
                } else if let d = Double(newValue) {
                    user?.micronutrientGoals[nutrientId] = d
                }
            }
        )
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

    NavigationStack {
        MicronutrientGoalsView()
    }
}
