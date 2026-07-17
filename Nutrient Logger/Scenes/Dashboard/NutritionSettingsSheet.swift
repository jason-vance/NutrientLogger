//
//  NutritionSettingsSheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI
import SwinjectAutoregistration

struct NutritionSettingsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics

    // Goals
    @State private var user: User?
    @State private var loadedUser: User?

    @AppStorage(WaterUnit.appStorageKey) private var preferredWaterUnitRaw: String = WaterUnit.cups.rawValue

    // Vitamins
    @AppStorage("nutrientCustomize_vitamins_order") private var vitaminsOrderRaw: String = ""
    @AppStorage("nutrientCustomize_vitamins_hidden") private var vitaminsHiddenRaw: String = ""

    // Minerals
    @AppStorage("nutrientCustomize_minerals_order") private var mineralsOrderRaw: String = ""
    @AppStorage("nutrientCustomize_minerals_hidden") private var mineralsHiddenRaw: String = ""

    // Lipids
    @AppStorage("nutrientCustomize_lipids_order") private var lipidsOrderRaw: String = ""
    @AppStorage("nutrientCustomize_lipids_hidden") private var lipidsHiddenRaw: String = ""

    // Amino Acids
    @AppStorage("nutrientCustomize_aminoAcids_order") private var aminoAcidsOrderRaw: String = ""
    @AppStorage("nutrientCustomize_aminoAcids_hidden") private var aminoAcidsHiddenRaw: String = ""

    @State private var showMicronutrientGoals = false
    @State private var showNutrientBalances = false

    @State private var vitamins: [String] = []
    @State private var minerals: [String] = []
    @State private var lipids: [String] = []
    @State private var aminoAcids: [String] = []

    // MARK: - Computed

    private var preferredWaterUnit: WaterUnit {
        WaterUnit(rawValue: preferredWaterUnitRaw) ?? .cups
    }

    // MARK: - Helpers

    private func fetchUser() {
        let loaded = userService.currentUser
        self.loadedUser = loaded
        self.user = loaded
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

    private func goalBinding(
        get: @escaping () -> Double?,
        set: @escaping (Double?) -> Void,
        goalName: String
    ) -> Binding<Double?> {
        Binding(
            get: get,
            set: { newValue in
                let hadGoal = get() != nil
                set(newValue)
                if !hadGoal && newValue != nil {
                    engagementAnalytics.goalSet(goalName: goalName)
                }
            }
        )
    }

    private func displayName(for nutrientId: String) -> String {
        FdcNutrientGroupMapper.nutrientDisplayNames[nutrientId]
            ?? FdcNutrientGroupMapper.NutrientNameOverrides[nutrientId]
            ?? nutrientId
    }

    private func enabledBinding(for nutrientId: String, hiddenRaw: Binding<String>) -> Binding<Bool> {
        Binding(
            get: {
                let hidden = Set(hiddenRaw.wrappedValue.split(separator: ",").map(String.init).filter { !$0.isEmpty })
                return !hidden.contains(nutrientId)
            },
            set: { isEnabled in
                var hidden = Set(hiddenRaw.wrappedValue.split(separator: ",").map(String.init).filter { !$0.isEmpty })
                if isEnabled { hidden.remove(nutrientId) } else { hidden.insert(nutrientId) }
                hiddenRaw.wrappedValue = hidden.joined(separator: ",")
            }
        )
    }

    private func effectiveOrder(raw: String, default defaultList: [String]) -> [String] {
        if raw.isEmpty { return defaultList }
        return raw.split(separator: ",").map(String.init)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                GoalsSection()
                NutrientGroupSection(
                    title: "Vitamins",
                    items: $vitamins,
                    hiddenRaw: $vitaminsHiddenRaw,
                    onMove: { from, to in
                        vitamins.move(fromOffsets: from, toOffset: to)
                        vitaminsOrderRaw = vitamins.joined(separator: ",")
                    }
                )
                NutrientGroupSection(
                    title: "Minerals",
                    items: $minerals,
                    hiddenRaw: $mineralsHiddenRaw,
                    onMove: { from, to in
                        minerals.move(fromOffsets: from, toOffset: to)
                        mineralsOrderRaw = minerals.joined(separator: ",")
                    }
                )
                NutrientGroupSection(
                    title: "Lipids",
                    items: $lipids,
                    hiddenRaw: $lipidsHiddenRaw,
                    onMove: { from, to in
                        lipids.move(fromOffsets: from, toOffset: to)
                        lipidsOrderRaw = lipids.joined(separator: ",")
                    }
                )
                NutrientGroupSection(
                    title: "Amino Acids",
                    items: $aminoAcids,
                    hiddenRaw: $aminoAcidsHiddenRaw,
                    onMove: { from, to in
                        aminoAcids.move(fromOffsets: from, toOffset: to)
                        aminoAcidsOrderRaw = aminoAcids.joined(separator: ",")
                    }
                )
            }
            .environment(\.editMode, .constant(.active))
            .scrollDismissesKeyboard(.immediately)
            .navigationDestination(isPresented: $showMicronutrientGoals) {
                MicronutrientGoalsView()
            }
            .navigationDestination(isPresented: $showNutrientBalances) {
                NutrientBalanceSettingsView()
            }
            .navigationTitle("Nutrition Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                fetchUser()
                vitamins = effectiveOrder(raw: vitaminsOrderRaw, default: DashboardVitaminsSection.orderedWhitelist)
                minerals = effectiveOrder(raw: mineralsOrderRaw, default: DashboardMineralsSection.orderedWhitelist)
                    .filter { !DashboardMineralsSection.permanentlyExcluded.contains($0) }
                lipids = effectiveOrder(raw: lipidsOrderRaw, default: DashboardLipidsSection.orderedWhitelist)
                aminoAcids = effectiveOrder(raw: aminoAcidsOrderRaw, default: DashboardAminoAcidsSection.orderedWhitelist)
            }
            .onChange(of: user) { saveUser() }
        }
    }

    // MARK: - Goals

    @ViewBuilder private func GoalsSection() -> some View {
        Section {
            GoalRow(
                "Calories",
                value: goalBinding(
                    get: { user?.calorieGoal },
                    set: { user?.calorieGoal = $0 },
                    goalName: "calorie"
                ),
                unit: "kcal",
                defaultValue: NutrientGoalDefaults.defaultCalorieGoal(for: user ?? User())
            )
            GoalRow(
                "Carbs",
                value: goalBinding(
                    get: { user?.carbsGoalGrams },
                    set: { user?.carbsGoalGrams = $0 },
                    goalName: "carbs"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultCarbsGoal(for: user ?? User())
            )
            GoalRow(
                "Fat",
                value: goalBinding(
                    get: { user?.fatGoalGrams },
                    set: { user?.fatGoalGrams = $0 },
                    goalName: "fat"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultFatGoal(for: user ?? User())
            )
            GoalRow(
                "Protein",
                value: goalBinding(
                    get: { user?.proteinGoalGrams },
                    set: { user?.proteinGoalGrams = $0 },
                    goalName: "protein"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultProteinGoal(for: user ?? User())
            )
            WaterGoalRow()
            Button {
                showMicronutrientGoals = true
            } label: {
                VStack {
                    HStack {
                        Text("Micronutrient Goals")
                        if !subscriptionManager.isSubscribed {
                            Text("PREMIUM")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule().foregroundStyle(Color.accentColor.gradient)
                                }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Set custom targets for vitamins and minerals")
                        Spacer()
                    }
                    .font(.caption)
                }
                .foregroundStyle(Color.primary)
            }
            Button {
                showNutrientBalances = true
            } label: {
                VStack {
                    HStack {
                        Text("Nutrient Balances")
                        if !subscriptionManager.isSubscribed {
                            Text("PREMIUM")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule().foregroundStyle(Color.accentColor.gradient)
                                }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Watch nutrients that are out of proportion, like sodium vs. potassium")
                        Spacer()
                    }
                    .font(.caption)
                }
                .foregroundStyle(Color.primary)
            }
        } header: {
            Text("Nutrition Goals")
        }
    }

    @ViewBuilder private func GoalRow(
        _ title: String,
        value: Binding<Double?>,
        unit: String,
        defaultValue: Double
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(
                "\(defaultValue.formatted(maxDigits: 0))",
                text: Binding(
                    get: {
                        if let v = value.wrappedValue {
                            return "\(v.formatted(maxDigits: 0))"
                        }
                        return ""
                    },
                    set: { newValue in
                        if newValue.isEmpty {
                            value.wrappedValue = nil
                        } else if let d = Double(newValue) {
                            value.wrappedValue = d
                        }
                    }
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: 100)
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func WaterGoalRow() -> some View {
        GoalRow(
            "Water",
            value: Binding(
                get: {
                    guard let grams = user?.waterGoalGrams else { return nil }
                    return preferredWaterUnit.fromGrams(grams)
                },
                set: { newValue in
                    let hadGoal = user?.waterGoalGrams != nil
                    user?.waterGoalGrams = newValue.map { preferredWaterUnit.toGrams($0) }
                    if !hadGoal && newValue != nil {
                        engagementAnalytics.goalSet(goalName: "water")
                    }
                }
            ),
            unit: preferredWaterUnit.rawValue,
            defaultValue: preferredWaterUnit.fromGrams(
                preferredWaterUnit.defaultGoalGrams(gender: user?.gender ?? .unknown)
            )
        )
        HStack {
            Text("Water Unit")
                .font(.subheadline)
            Spacer()
            Picker("Water Unit", selection: $preferredWaterUnitRaw) {
                ForEach(WaterUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 180)
        }
    }

    // MARK: - Nutrient Customization

    @ViewBuilder private func NutrientGroupSection(
        title: String,
        items: Binding<[String]>,
        hiddenRaw: Binding<String>,
        onMove: @escaping (IndexSet, Int) -> Void
    ) -> some View {
        Section {
            ForEach(items.wrappedValue, id: \.self) { nutrientId in
                HStack {
                    Toggle("", isOn: enabledBinding(for: nutrientId, hiddenRaw: hiddenRaw))
                        .labelsHidden()
                    Text(displayName(for: nutrientId))
                }
            }
            .onMove(perform: onMove)
        } header: {
            Text(title)
        } footer: {
            Text("Drag to reorder and build your Nutrition tab exactly the way you want it. Disabled nutrients are hidden.")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NutritionSettingsSheet()
        .environmentObject(SubscriptionManager(isForScreenshots: true))
}
