//
//  BarcodeProductReviewView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/22/26.
//

import SwiftUI

struct BarcodeProductReviewView: View {

    let product: OpenFoodFactsProduct
    let onSave: () -> Void
    let onCancel: () -> Void

    private var displayName: String {
        if let brand = product.brand, !brand.isEmpty {
            return "\(brand) - \(product.name)"
        }
        return product.name
    }

    private func nutrimentValue(_ offKey: String) -> Double? {
        let mapping: [String: String] = [
            "calories": "energy-kcal_100g",
            "protein": "proteins_100g",
            "fat": "fat_100g",
            "carbs": "carbohydrates_100g",
        ]
        guard let key = mapping[offKey],
              let per100g = rawNutriments[key],
              per100g > 0 else {
            return nil
        }
        let scale = (product.servingQuantityGrams ?? 100.0) / 100.0
        return per100g * scale
    }

    private var rawNutriments: [String: Double] {
        var result: [String: Double] = [:]
        // Re-parse from the product's already-mapped nutriments using reverse mapping
        // But simpler: the product.nutriments already has FDC numbers mapped.
        // We need the raw OFF keys for display. Let's just use the mapped values directly.
        return result
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(displayName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let servingSize = product.servingSize, !servingSize.isEmpty {
                Text("Serving: \(servingSize)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            MacroSummary(nutriments: product.nutriments, servingGrams: product.servingQuantityGrams ?? 100.0)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onSave) {
                    Label("Save & View Details", systemImage: "checkmark.circle.fill")
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
}

private struct MacroSummary: View {

    let nutriments: [String: Double]
    let servingGrams: Double

    private var scale: Double { servingGrams / 100.0 }

    private func scaled(_ fdcNumber: String) -> Double? {
        guard let value = nutriments[fdcNumber], value > 0 else { return nil }
        return value * scale
    }

    var body: some View {
        HStack(spacing: 16) {
            MacroItem(label: "Cal", value: scaled("208"), unit: "")
            MacroItem(label: "Protein", value: scaled("203"), unit: "g")
            MacroItem(label: "Fat", value: scaled("204"), unit: "g")
            MacroItem(label: "Carbs", value: scaled("205"), unit: "g")
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        }
    }
}

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
