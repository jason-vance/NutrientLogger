//
//  NutrientCustomizeSheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI

struct NutrientCustomizeSheet: View {

    @Environment(\.dismiss) private var dismiss

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

    @State private var vitamins: [String] = []
    @State private var minerals: [String] = []
    @State private var lipids: [String] = []
    @State private var aminoAcids: [String] = []

    // MARK: - Helpers

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
            .navigationTitle("Customize Nutrients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                vitamins = effectiveOrder(raw: vitaminsOrderRaw, default: DashboardVitaminsSection.orderedWhitelist)
                minerals = effectiveOrder(raw: mineralsOrderRaw, default: DashboardMineralsSection.orderedWhitelist)
                lipids = effectiveOrder(raw: lipidsOrderRaw, default: DashboardLipidsSection.orderedWhitelist)
                aminoAcids = effectiveOrder(raw: aminoAcidsOrderRaw, default: DashboardAminoAcidsSection.orderedWhitelist)
            }
        }
    }

    // MARK: - Section

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
            Text("Drag to reorder. Disabled nutrients are hidden from the Nutrition tab.")
        }
    }
}

#Preview {
    NutrientCustomizeSheet()
}
