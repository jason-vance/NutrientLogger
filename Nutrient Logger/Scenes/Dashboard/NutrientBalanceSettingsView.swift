//
//  NutrientBalanceSettingsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/17/26.
//

import SwiftUI

/// Lets the user choose which nutrient *balances* the weekly watch card checks — turning built-in
/// balances on/off and adding their own. Premium, like the card itself; non-subscribers see the
/// balances but can't change them.
struct NutrientBalanceSettingsView: View {

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @AppStorage(NutrientBalanceSettings.hiddenKey) private var hiddenRaw: String = ""
    @AppStorage(NutrientBalanceSettings.customKey) private var customRaw: String = ""

    @State private var showMarketingView: Bool = false
    @State private var editorMode: EditorMode?

    /// Drives the create/edit sheet. Identifiable so a single `.sheet(item:)` covers both.
    private enum EditorMode: Identifiable {
        case new
        case edit(NutrientRatio)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let ratio): return ratio.id
            }
        }
    }

    private var customRatios: [NutrientRatio] {
        NutrientBalanceSettings.customRatios(from: customRaw)
    }

    private var isLocked: Bool { !subscriptionManager.isSubscribed }

    var body: some View {
        List {
            if isLocked {
                PremiumBanner()
            }

            Section {
                ForEach(NutrientBalanceDefaults.all) { ratio in
                    BalanceRow(ratio)
                }
            } header: {
                Text("Built-in Balances")
            } footer: {
                Text("Balances flag nutrients that are out of proportion to each other, rather than simply too high or too low. Turn off any you'd rather not track.")
            }

            Section {
                ForEach(customRatios) { ratio in
                    CustomBalanceRow(ratio)
                }
                .onDelete(perform: isLocked ? nil : deleteCustom)

                Button {
                    if isLocked {
                        showMarketingView = true
                    } else {
                        editorMode = .new
                    }
                } label: {
                    Label("Add Custom Balance", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Your Balances")
            } footer: {
                Text("Create your own balance between any two nutrients and set the ratio you want to stay within. Tap one to edit it.")
            }
        }
        .navigationTitle("Nutrient Balances")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorMode) { mode in
            switch mode {
            case .new:
                NutrientBalanceEditorView(onSave: upsert)
            case .edit(let ratio):
                NutrientBalanceEditorView(existing: ratio, onSave: upsert)
            }
        }
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .weeklyNutrientWatch)
        }
    }

    @ViewBuilder private func BalanceRow(_ ratio: NutrientRatio) -> some View {
        Toggle(isOn: enabledBinding(for: ratio.id)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ratio.name)
                Text(ratio.targetText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(isLocked)
    }

    @ViewBuilder private func CustomBalanceRow(_ ratio: NutrientRatio) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: enabledBinding(for: ratio.id))
                .labelsHidden()
            Button {
                editorMode = .edit(ratio)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ratio.name)
                            .foregroundStyle(Color.primary)
                        Text(ratio.targetText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .disabled(isLocked)
    }

    private func enabledBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { !NutrientBalanceSettings.hiddenIds(from: hiddenRaw).contains(id) },
            set: { isEnabled in
                var hidden = NutrientBalanceSettings.hiddenIds(from: hiddenRaw)
                if isEnabled { hidden.remove(id) } else { hidden.insert(id) }
                hiddenRaw = NutrientBalanceSettings.encodeHidden(hidden)
            }
        )
    }

    /// Inserts a new custom balance or replaces the existing one with the same id (edit).
    private func upsert(_ ratio: NutrientRatio) {
        var ratios = customRatios
        if let index = ratios.firstIndex(where: { $0.id == ratio.id }) {
            ratios[index] = ratio
        } else {
            ratios.append(ratio)
        }
        customRaw = NutrientBalanceSettings.encode(customRatios: ratios)
    }

    private func deleteCustom(at offsets: IndexSet) {
        var ratios = customRatios
        ratios.remove(atOffsets: offsets)
        customRaw = NutrientBalanceSettings.encode(customRatios: ratios)
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
                Text("Subscribe to customize which nutrient balances you track and add your own.")
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
        }
    }
}

/// Form for creating a custom balance between two single nutrients, with a healthy band. Kept
/// deliberately simple (single nutrient per side) — the built-in balances cover the multi-nutrient
/// cases like omega-6:omega-3.
struct NutrientBalanceEditorView: View {

    @Environment(\.dismiss) private var dismiss

    /// The id of the balance being edited, or nil when creating a new one. Preserved on save so an
    /// edit replaces the same balance rather than adding a duplicate.
    private let existingId: String?
    let onSave: (NutrientRatio) -> Void

    @State private var numeratorId: String
    @State private var denominatorId: String
    @State private var maxText: String
    @State private var minText: String

    init(existing: NutrientRatio? = nil, onSave: @escaping (NutrientRatio) -> Void) {
        self.existingId = existing?.id
        self.onSave = onSave
        _numeratorId = State(initialValue: existing?.numeratorNutrientIds.first ?? FdcNutrientGroupMapper.NutrientNumber_Sodium_Na)
        _denominatorId = State(initialValue: existing?.denominatorNutrientIds.first ?? FdcNutrientGroupMapper.NutrientNumber_Potassium_K)
        _maxText = State(initialValue: existing?.healthyMax.map { $0.formatted(maxDigits: 2) } ?? "")
        _minText = State(initialValue: existing?.healthyMin.map { $0.formatted(maxDigits: 2) } ?? "")
    }

    /// Vitamins + minerals, the nutrients with reliable display names and food-data coverage.
    private static let selectableIds: [String] =
        DashboardMineralsSection.orderedWhitelist + DashboardVitaminsSection.orderedWhitelist

    private func name(for id: String) -> String {
        FdcNutrientGroupMapper.nutrientDisplayNames[id]
            ?? FdcNutrientGroupMapper.NutrientNameOverrides[id]
            ?? id
    }

    private var maxValue: Double? { Double(maxText) }
    private var minValue: Double? { Double(minText) }

    private var canSave: Bool {
        guard numeratorId != denominatorId else { return false }
        // At least one bound, and if both are set the band must be valid.
        if let min = minValue, let max = maxValue { return min < max }
        return maxValue != nil || minValue != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nutrients") {
                    Picker("Top", selection: $numeratorId) {
                        ForEach(Self.selectableIds, id: \.self) { Text(name(for: $0)).tag($0) }
                    }
                    Picker("Bottom", selection: $denominatorId) {
                        ForEach(Self.selectableIds, id: \.self) { Text(name(for: $0)).tag($0) }
                    }
                    if numeratorId == denominatorId {
                        Text("Pick two different nutrients.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    BandField(label: "Flag when above", suffix: ": 1", text: $maxText)
                    BandField(label: "Flag when below", suffix: ": 1", text: $minText)
                } header: {
                    Text("Healthy Range")
                } footer: {
                    Text("The ratio is \(name(for: numeratorId)) ÷ \(name(for: denominatorId)) by weight. Set an upper bound, a lower bound, or both.")
                }
            }
            .navigationTitle(existingId == nil ? "New Balance" : "Edit Balance")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let numLabel = name(for: numeratorId)
        let denLabel = name(for: denominatorId)
        let ratio = NutrientRatio(
            id: existingId ?? UUID().uuidString,
            name: "\(numLabel) : \(denLabel)",
            numeratorLabel: numLabel,
            denominatorLabel: denLabel,
            numeratorNutrientIds: [numeratorId],
            denominatorNutrientIds: [denominatorId],
            healthyMax: maxValue,
            healthyMin: minValue,
            explanation: "A custom balance you're tracking: \(numLabel) relative to \(denLabel).",
            isBuiltIn: false
        )
        onSave(ratio)
        dismiss()
    }

    @ViewBuilder private func BandField(label: String, suffix: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .bold()
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: 80)
            Text(suffix)
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }
}

#Preview("Settings") {
    NavigationStack {
        NutrientBalanceSettingsView()
    }
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}

#Preview("Editor") {
    NutrientBalanceEditorView { _ in }
}
