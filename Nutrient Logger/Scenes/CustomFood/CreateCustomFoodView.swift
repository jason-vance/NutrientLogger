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
    let onSaved: ((CustomFood) -> Void)?

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

    /// True when the serving unit is typed in rather than picked from `commonUnits`.
    @State private var usesOtherUnit: Bool = false
    /// Whether the user has typed a gram weight, so picking "oz" doesn't overwrite it.
    @State private var hasEditedGrams: Bool = false

    /// The units on most nutrition labels, as one-tap pills. Anything else is "Other…".
    private static let commonUnits = ["serving", "cup", "oz", "slice", "piece", "tbsp", "scoop", "bar"]
    private static let otherUnit = "Other…"
    private static let unitField = "unit"

    @FocusState private var focusedField: String?
    private static let nameField = "name"
    private static let caloriesField = "208"
    private static let gramsField = "grams"

    /// Every field on screen, top to bottom, for the keyboard bar's previous/next arrows.
    private var fieldOrder: [String] {
        var fields = [Self.nameField]
        if usesOtherUnit { fields.append(Self.unitField) }
        fields.append(Self.gramsField)
        let groups: [(String, Bool)] = [
            ("Macros", true),
            ("Fatty Acids", showFattyAcids),
            ("Vitamins", showVitamins),
            ("Minerals", showMinerals),
            ("Amino Acids", showAminoAcids),
        ]
        for (group, isShown) in groups where isShown {
            fields += fieldsForGroup(group).map(\.fdcNumber)
        }
        return fields + addedOtherFdcNumbers
    }

    private func focusedFieldMoved(by offset: Int) -> String? {
        guard let focusedField, let index = fieldOrder.firstIndex(of: focusedField) else { return nil }
        let next = index + offset
        return fieldOrder.indices.contains(next) ? fieldOrder[next] : nil
    }

    private var isEditing: Bool { existingFood != nil }

    init(
        existingFood: CustomFood? = nil,
        initialName: String = "",
        onSaved: ((CustomFood) -> Void)? = nil
    ) {
        self.existingFood = existingFood
        self.onSaved = onSaved
        _name = State(initialValue: initialName)
    }

    // MARK: - Derived

    private var fieldsForGroup: (String) -> [CustomFood.FormField] {
        { group in CustomFood.formFields.filter { $0.group == group } }
    }

    private var availableOtherFields: [CustomFood.FormField] {
        CustomFood.otherFields.filter { !addedOtherFdcNumbers.contains($0.fdcNumber) }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedUnit: String { servingUnit.trimmingCharacters(in: .whitespaces) }

    private var saveButtonTitle: String {
        if trimmedName.isEmpty { return "Add a name" }
        if trimmedUnit.isEmpty { return "Pick a serving" }
        if isEditing { return "Save Changes" }
        // From search, saving goes straight on to logging the food.
        return onSaved != nil ? "Save and Log" : "Save Food"
    }

    /// "1 cup (240 g) · 210 kcal"
    private var saveButtonDetail: String? {
        guard !trimmedUnit.isEmpty, let grams = Double(servingGramWeightText), grams > 0 else { return nil }
        var parts = ["1 \(trimmedUnit) (\(grams.formatted(maxDigits: 1)) g)"]
        if let calories = Double(nutrientTexts[Self.caloriesField] ?? "") {
            parts.append("\(calories.formatted(maxDigits: 0)) kcal")
        }
        return parts.joined(separator: " · ")
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
        usesOtherUnit = !Self.commonUnits.contains(food.servingUnit)
        servingGramWeightText = food.servingGramWeight.formatted(maxDigits: 2)
        hasEditedGrams = true

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
        onSaved?(food)
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
        .safeAreaInset(edge: .bottom) {
            // While typing, the bar above the keyboard saves instead, so the big button doesn't
            // ride up with the keyboard and cover the fields.
            if focusedField == nil {
                LogActionButton(title: saveButtonTitle, detail: saveButtonDetail, isEnabled: canSave) { save() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .toolbar { KeyboardBar() }
        .onAppear {
            if let food = existingFood { populate(from: food) }
            engagementAnalytics.screenViewed(screenName: isEditing ? "EditCustomFood" : "CreateCustomFood")
        }
        .task {
            guard !isEditing else { return }
            // Wait for the sheet to finish sliding up, or the keyboard won't appear.
            try? await Task.sleep(for: .milliseconds(450))
            focusedField = name.isEmpty ? Self.nameField : Self.caloriesField
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
    }

    /// Number pads have no return key, so this is how you move between fields and save.
    @ToolbarContentBuilder private func KeyboardBar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            let previous = focusedFieldMoved(by: -1)
            let next = focusedFieldMoved(by: 1)
            Button {
                focusedField = previous
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(previous == nil)
            .accessibilityLabel("Previous field")
            Button {
                focusedField = next
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(next == nil)
            .accessibilityLabel("Next field")
            Spacer()
            if canSave {
                Button(isEditing ? "Save" : (onSaved != nil ? "Save and Log" : "Save")) {
                    focusedField = nil
                    save()
                }
                .bold()
            } else {
                Button("Done") { focusedField = nil }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private func FoodInfoSection() -> some View {
        Section("Food Info") {
            HStack {
                Text("Name")
                Spacer()
                TextField("e.g. Homemade Granola", text: $name)
                    .focused($focusedField, equals: Self.nameField)
                    .submitLabel(.next)
                    .onSubmit { focusedField = Self.caloriesField }
                    .multilineTextAlignment(.trailing)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            .listRowDefaultModifiers()

            ServingUnitRow()

            HStack {
                Text("Grams per \(trimmedUnit.isEmpty ? "serving" : trimmedUnit)")
                Spacer()
                TextField("100", text: Binding(
                    get: { servingGramWeightText },
                    set: { servingGramWeightText = $0; hasEditedGrams = true }
                ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: Self.gramsField)
                    .multilineTextAlignment(.trailing)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
            .listRowDefaultModifiers()
        }
    }

    /// The serving as one-tap pills, since nearly every label uses one of a few units.
    @ViewBuilder private func ServingUnitRow() -> some View {
        let options = Self.commonUnits + [Self.otherUnit]
        VStack(alignment: .leading, spacing: 8) {
            Text("Serving")
            LogPillRow(
                items: options,
                labels: options,
                isSelected: { option in
                    option == Self.otherUnit ? usesOtherUnit : (!usesOtherUnit && option == servingUnit)
                },
                onSelect: { option in
                    if option == Self.otherUnit {
                        usesOtherUnit = true
                        servingUnit = ""
                        focusedField = Self.unitField
                    } else {
                        usesOtherUnit = false
                        servingUnit = option
                        // An ounce always weighs the same, so fill it in.
                        if option == "oz" && !hasEditedGrams { servingGramWeightText = "28.35" }
                    }
                }
            )
            if usesOtherUnit {
                TextField("e.g. muffin, container, packet", text: $servingUnit)
                    .focused($focusedField, equals: Self.unitField)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
        .listRowDefaultModifiers()
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
            .focused($focusedField, equals: field.fdcNumber)
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
