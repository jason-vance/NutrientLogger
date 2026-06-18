//
//  CreateCustomFoodView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/16/26.
//

import SwiftUI
import SwinjectAutoregistration

struct CreateCustomFoodView: View {

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var customFoodDatabase: CustomFoodDatabase
    @Inject private var engagementAnalytics: EngagementAnalytics

    let existingFood: CustomFood?

    @State private var name: String = ""
    @State private var servingUnit: String = "serving"
    @State private var servingGramWeightText: String = "100"
    @State private var nutrientTexts: [String: String] = [:]

    @State private var showVitamins: Bool = false
    @State private var showMinerals: Bool = false
    @State private var showFattyAcids: Bool = false
    @State private var showAminoAcids: Bool = false

    @State private var addedOtherFdcNumbers: [String] = []
    @State private var showOtherPicker: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var isEditing: Bool { existingFood != nil }

    init(existingFood: CustomFood? = nil) {
        self.existingFood = existingFood
    }

    // MARK: - Derived

    private var fieldsForGroup: (String) -> [CustomFood.FormField] {
        { group in CustomFood.formFields.filter { $0.group == group } }
    }

    private var availableOtherFields: [CustomFood.FormField] {
        CustomFood.otherFields.filter { !addedOtherFdcNumbers.contains($0.fdcNumber) }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !servingUnit.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(servingGramWeightText) ?? 0) > 0
    }

    // MARK: - Actions

    private func populate(from food: CustomFood) {
        name = food.name
        servingUnit = food.servingUnit
        servingGramWeightText = food.servingGramWeight.formatted(maxDigits: 2)

        let formFdcNumbers = Set(CustomFood.formFields.map { $0.fdcNumber })

        for (fdcNumber, amount) in food.nutrientAmounts where amount > 0 {
            nutrientTexts[fdcNumber] = amount.formatted(maxDigits: 4)
            if !formFdcNumbers.contains(fdcNumber),
               CustomFood.otherFields.contains(where: { $0.fdcNumber == fdcNumber }),
               !addedOtherFdcNumbers.contains(fdcNumber) {
                addedOtherFdcNumbers.append(fdcNumber)
            }
        }

        showFattyAcids = fieldsForGroup("Fatty Acids").contains { nutrientTexts[$0.fdcNumber] != nil }
        showAminoAcids = fieldsForGroup("Amino Acids").contains { nutrientTexts[$0.fdcNumber] != nil }
        showVitamins   = fieldsForGroup("Vitamins").contains { nutrientTexts[$0.fdcNumber] != nil }
        showMinerals   = fieldsForGroup("Minerals").contains { nutrientTexts[$0.fdcNumber] != nil }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a food name."
            showAlert = true
            return
        }
        guard let gramWeight = Double(servingGramWeightText), gramWeight > 0 else {
            alertMessage = "Serving gram weight must be greater than zero."
            showAlert = true
            return
        }

        var amounts: [String: Double] = [:]
        for (fdcNumber, text) in nutrientTexts {
            if let value = Double(text), value > 0 {
                amounts[fdcNumber] = value
            }
        }

        let food = CustomFood(
            customFoodId: existingFood?.customFoodId ?? customFoodDatabase.nextId(),
            created: existingFood?.created ?? Date(),
            name: trimmedName,
            servingUnit: servingUnit.trimmingCharacters(in: .whitespaces),
            servingGramWeight: gramWeight,
            nutrientAmounts: amounts
        )
        customFoodDatabase.save(food)
        if isEditing {
            engagementAnalytics.customFoodEdited()
        } else {
            engagementAnalytics.customFoodCreated()
        }
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - Body

    var body: some View {
        List {
            FoodInfoSection()
            CollapsibleSection(title: "Macros & Key Nutrients", isExpanded: .constant(true)) {
                ForEach(fieldsForGroup("Macros")) { NutrientRow(field: $0) }
            }
            CollapsibleSection(title: "Fatty Acids", isExpanded: $showFattyAcids) {
                ForEach(fieldsForGroup("Fatty Acids")) { NutrientRow(field: $0) }
            }
            CollapsibleSection(title: "Vitamins", isExpanded: $showVitamins) {
                ForEach(fieldsForGroup("Vitamins")) { NutrientRow(field: $0) }
            }
            CollapsibleSection(title: "Minerals", isExpanded: $showMinerals) {
                ForEach(fieldsForGroup("Minerals")) { NutrientRow(field: $0) }
            }
            CollapsibleSection(title: "Amino Acids", isExpanded: $showAminoAcids) {
                ForEach(fieldsForGroup("Amino Acids")) { NutrientRow(field: $0) }
            }
            OtherNutrientsSection()
        }
        .scrollDismissesKeyboard(.interactively)
        .listDefaultModifiers()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .onAppear {
            if let food = existingFood { populate(from: food) }
            engagementAnalytics.screenViewed(screenName: isEditing ? "EditCustomFood" : "CreateCustomFood")
        }
        .alert(alertMessage, isPresented: $showAlert) { }
        .sheet(isPresented: $showOtherPicker) {
            NutrientPickerSheet(fields: availableOtherFields) { field in
                addedOtherFdcNumbers.append(field.fdcNumber)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(isEditing ? "Edit Food" : "New Custom Food")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { save() } label: { Image(systemName: "checkmark") }
                .disabled(!canSave)
        }
    }

    // MARK: - Sections

    @ViewBuilder private func FoodInfoSection() -> some View {
        Section("Food Info") {
            HStack {
                Text("Name")
                Spacer()
                TextField("e.g. Homemade Granola", text: $name)
                    .multilineTextAlignment(.trailing)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            .listRowDefaultModifiers()

            HStack {
                Text("Serving Unit")
                Spacer()
                TextField("e.g. serving, cup, oz", text: $servingUnit)
                    .multilineTextAlignment(.trailing)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            .listRowDefaultModifiers()

            HStack {
                Text("Grams per Serving")
                Spacer()
                TextField("100", text: $servingGramWeightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            .listRowDefaultModifiers()
        }
    }

    @ViewBuilder private func OtherNutrientsSection() -> some View {
        Section {
            ForEach(addedOtherFdcNumbers, id: \.self) { fdcNumber in
                if let field = CustomFood.otherFields.first(where: { $0.fdcNumber == fdcNumber }) {
                    NutrientRow(field: field)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                addedOtherFdcNumbers.removeAll { $0 == fdcNumber }
                                nutrientTexts.removeValue(forKey: fdcNumber)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            if !availableOtherFields.isEmpty {
                Button {
                    showOtherPicker = true
                } label: {
                    Label("Add Nutrient", systemImage: "plus.circle")
                }
                .listRowDefaultModifiers()
            }
        } header: {
            HStack {
                Text("Other Nutrients")
                    .listSectionHeader()
                if !addedOtherFdcNumbers.isEmpty {
                    Text("\(addedOtherFdcNumbers.count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
                Spacer()
            }
        }
    }

    @ViewBuilder private func NutrientRow(field: CustomFood.FormField) -> some View {
        HStack {
            Text(field.name)
            Spacer()
            TextField("0", text: Binding(
                get: { nutrientTexts[field.fdcNumber] ?? "" },
                set: { nutrientTexts[field.fdcNumber] = $0 }
            ))
            .keyboardType(.decimalPad)
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

// MARK: - Nutrient picker sheet

private struct NutrientPickerSheet: View {

    @Environment(\.presentationMode) private var presentationMode

    let fields: [CustomFood.FormField]
    let onSelect: (CustomFood.FormField) -> Void

    @State private var query: String = ""

    private var grouped: [(String, [CustomFood.FormField])] {
        let filtered = query.isEmpty
            ? fields
            : fields.filter { $0.name.localizedCaseInsensitiveContains(query) }
        let groups = Dictionary(grouping: filtered, by: \.group)
        return groups.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { groupName, groupFields in
                    Section(groupName) {
                        ForEach(groupFields) { field in
                            Button {
                                onSelect(field)
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                HStack {
                                    Text(field.name)
                                        .foregroundStyle(Color.text)
                                    Spacer()
                                    Text(field.unit)
                                        .foregroundStyle(.secondary)
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search nutrients")
            .navigationTitle("Add Nutrient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        CreateCustomFoodView()
    }
    .environmentObject(CustomFoodDatabase())
}
