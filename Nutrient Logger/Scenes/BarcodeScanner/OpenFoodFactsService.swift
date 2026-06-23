//
//  OpenFoodFactsService.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/22/26.
//

import Foundation

struct OpenFoodFactsProduct {
    let name: String
    let brand: String?
    let servingSize: String?
    let servingQuantityGrams: Double?
    let nutriments: [String: Double]
    let barcode: String
}

class OpenFoodFactsService {

    static let shared = OpenFoodFactsService()

    private init() {}

    func lookupBarcode(_ barcode: String) async throws -> OpenFoodFactsProduct? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,serving_size,serving_quantity,nutriments"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("NutrientLogger iOS App - contact jasonvance77@gmail.com", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int,
              status == 1,
              let product = json["product"] as? [String: Any] else {
            return nil
        }

        guard let name = product["product_name"] as? String, !name.isEmpty else {
            return nil
        }

        let brand = product["brands"] as? String
        let servingSize = product["serving_size"] as? String

        var servingQuantityGrams: Double? = nil
        if let sq = product["serving_quantity"] as? Double, sq > 0 {
            servingQuantityGrams = sq
        } else if let sq = product["serving_quantity"] as? String, let val = Double(sq), val > 0 {
            servingQuantityGrams = val
        }

        let nutriments = Self.parseNutriments(product["nutriments"] as? [String: Any] ?? [:])

        return OpenFoodFactsProduct(
            name: name,
            brand: brand,
            servingSize: servingSize,
            servingQuantityGrams: servingQuantityGrams,
            nutriments: nutriments,
            barcode: barcode
        )
    }

    @MainActor func toCustomFood(_ product: OpenFoodFactsProduct, database: CustomFoodDatabase) -> CustomFood {
        let servingGrams = product.servingQuantityGrams ?? 100.0
        let scale = servingGrams / 100.0

        var nutrientAmounts: [String: Double] = [:]
        for (fdcNumber, per100g) in product.nutriments {
            let scaled = per100g * scale
            if scaled > 0 {
                nutrientAmounts[fdcNumber] = scaled
            }
        }

        var displayName = product.name
        if let brand = product.brand, !brand.isEmpty {
            displayName = "\(brand) - \(product.name)"
        }

        let servingUnit: String
        if let ss = product.servingSize, !ss.isEmpty {
            servingUnit = ss
        } else {
            servingUnit = "serving (\(Int(servingGrams))g)"
        }

        return CustomFood(
            customFoodId: database.nextId(),
            name: displayName,
            servingUnit: servingUnit,
            servingGramWeight: servingGrams,
            nutrientAmounts: nutrientAmounts,
            barcode: product.barcode
        )
    }

    // Maps Open Food Facts nutriment keys (per 100g) to FDC nutrient numbers,
    // converting from grams (OFF's standard) to each nutrient's expected unit.
    private static func parseNutriments(_ raw: [String: Any]) -> [String: Double] {
        var result: [String: Double] = [:]

        for (offKey, fdcNumber) in nutrimentMapping {
            var value: Double?
            if let v = raw[offKey] as? Double, v > 0 {
                value = v
            } else if let v = raw[offKey] as? String, let dbl = Double(v), dbl > 0 {
                value = dbl
            }
            guard let grams = value else { continue }

            let converted: Double
            switch CustomFood.nutrientUnit(for: fdcNumber) {
            case "mg":
                converted = grams * 1_000
            case "mcg":
                converted = grams * 1_000_000
            default: // "g", "kcal" — already in the correct unit
                converted = grams
            }
            result[fdcNumber] = converted
        }

        return result
    }

    // OFF per-100g key → FDC nutrient number
    private static let nutrimentMapping: [String: String] = [
        "energy-kcal_100g": "208",
        "proteins_100g": "203",
        "fat_100g": "204",
        "carbohydrates_100g": "205",
        "fiber_100g": "291",
        "sugars_100g": "269",
        "sodium_100g": "307",
        "cholesterol_100g": "601",
        "saturated-fat_100g": "606",
        "vitamin-a_100g": "320",
        "vitamin-c_100g": "401",
        "vitamin-d_100g": "328",
        "vitamin-e_100g": "323",
        "vitamin-k_100g": "430",
        "vitamin-b1_100g": "404",
        "vitamin-b2_100g": "405",
        "vitamin-pp_100g": "406",
        "pantothenic-acid_100g": "410",
        "vitamin-b6_100g": "415",
        "folates_100g": "435",
        "vitamin-b12_100g": "418",
        "choline_100g": "421",
        "biotin_100g": "416",
        "calcium_100g": "301",
        "iron_100g": "303",
        "magnesium_100g": "304",
        "phosphorus_100g": "305",
        "potassium_100g": "306",
        "zinc_100g": "309",
        "copper_100g": "312",
        "selenium_100g": "317",
        "manganese_100g": "315",
        "iodine_100g": "314",
        "chromium_100g": "310",
        "molybdenum_100g": "316",
        "fluoride_100g": "313",
        "trans-fat_100g": "605",
        "monounsaturated-fat_100g": "645",
        "polyunsaturated-fat_100g": "646",
        "alcohol_100g": "221",
        "caffeine_100g": "262",
    ]
}
