//
//  BarcodeProductReviewView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/22/26.
//

import SwiftUI

struct BarcodeProductReviewView: View {

    let product: OpenFoodFactsProduct
    let similarFoods: [FdcSearchableFood]
    let onSave: () -> Void
    let onCancel: () -> Void
    let onSelectSimilarFood: (FdcSearchableFood) -> Void

    @State private var showingSimilarFoods = false

    private var displayName: String {
        if let brand = product.brand, !brand.isEmpty {
            return "\(brand) - \(product.name)"
        }
        return product.name
    }

    private var servingScale: Double {
        (product.servingQuantityGrams ?? 100.0) / 100.0
    }

    private func scaledValue(for fdcNumber: String) -> Double? {
        guard let per100g = product.nutriments[fdcNumber], per100g > 0 else { return nil }
        return per100g * servingScale
    }

    private var nutrientGroups: [(name: String, fields: [CustomFood.FormField])] {
        let grouped = Dictionary(grouping: CustomFood.formFields) { $0.group }
        let order = ["Macros", "Vitamins", "Minerals", "Fatty Acids", "Amino Acids"]
        return order.compactMap { groupName in
            guard let fields = grouped[groupName] else { return nil }
            let available = fields.filter { scaledValue(for: $0.fdcNumber) != nil }
            guard !available.isEmpty else { return nil }
            return (name: groupName, fields: available)
        }
    }

    var body: some View {
        if showingSimilarFoods {
            SimilarFoodsPickerView(
                foods: similarFoods,
                onSelect: onSelectSimilarFood,
                onBack: { showingSimilarFoods = false }
            )
            .transition(.move(edge: .trailing))
        } else {
            nutrientReviewContent
                .transition(.move(edge: .leading))
        }
    }

    private var nutrientReviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                macroSummary
                nutrientDetailsSection

                if !similarFoods.isEmpty {
                    similarFoodsButton
                }

                actionButtons
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.top, 24)

            Text(displayName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let servingSize = product.servingSize, !servingSize.isEmpty {
                Text("Serving: \(servingSize)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var macroSummary: some View {
        HStack(spacing: 16) {
            MacroItem(label: "Cal", value: scaledValue(for: "208"), unit: "")
            MacroItem(label: "Protein", value: scaledValue(for: "203"), unit: "g")
            MacroItem(label: "Fat", value: scaledValue(for: "204"), unit: "g")
            MacroItem(label: "Carbs", value: scaledValue(for: "205"), unit: "g")
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
        .padding(.horizontal)
    }

    private var nutrientDetailsSection: some View {
        VStack(spacing: 12) {
            ForEach(nutrientGroups, id: \.name) { group in
                NutrientGroupSection(
                    name: group.name,
                    fields: group.fields,
                    scaledValue: scaledValue
                )
            }
        }
        .padding(.horizontal)
    }

    private var similarFoodsButton: some View {
        Button {
            withAnimation {
                showingSimilarFoods = true
            }
        } label: {
            HStack {
                Image(systemName: "carrot")
                Text("View Similar Foods (\(similarFoods.count))")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .foregroundStyle(.primary)
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onSave) {
                Label("Save as Custom Food", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(action: onCancel) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Nutrient Group Section

private struct NutrientGroupSection: View {

    let name: String
    let fields: [CustomFood.FormField]
    let scaledValue: (String) -> Double?

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(fields) { field in
                        if let value = scaledValue(field.fdcNumber) {
                            HStack {
                                Text(field.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(formatNutrientValue(value, unit: field.unit))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)

                            if field.id != fields.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }

    private func formatNutrientValue(_ value: Double, unit: String) -> String {
        if value >= 100 {
            return "\(Int(value)) \(unit)"
        } else if value >= 1 {
            return String(format: "%.1f \(unit)", value)
        } else {
            return String(format: "%.2f \(unit)", value)
        }
    }
}

// MARK: - Macro Item

private struct MacroItem: View {

    let label: String
    let value: Double?
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let value {
                Text("\(Int(value))\(unit)")
                    .font(.headline)
            } else {
                Text("—")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Similar Foods Picker

private struct SimilarFoodsPickerView: View {

    let foods: [FdcSearchableFood]
    let onSelect: (FdcSearchableFood) -> Void
    let onBack: () -> Void

    @State private var showInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button {
                        withAnimation {
                            onBack()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to Review")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                VStack(spacing: 8) {
                    Image(systemName: "carrot")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Similar Foods")
                        .font(.title2.bold())
                    Text("Choose a food from the built-in database for more complete nutrition data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 0) {
                    ForEach(foods, id: \.fdcId) { food in
                        Button {
                            onSelect(food)
                        } label: {
                            HStack {
                                Text(food.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }

                        if food.fdcId != foods.last?.fdcId {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
                .padding(.horizontal)
            }
        }
        .alert("About Similar Foods", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Scanned products may be missing some nutrient details. For the most complete nutrition data, try logging a similar food from our built-in database instead.")
        }
    }
}
