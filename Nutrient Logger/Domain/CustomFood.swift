//
//  CustomFood.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/16/26.
//

import Foundation

struct CustomFood: Identifiable, Codable, Equatable {

    var customFoodId: Int       // Negative unique int (e.g. -1, -2, …)
    var created: Date
    var name: String
    var servingUnit: String     // e.g. "serving", "tbsp", "cup", "oz", "g"
    var servingGramWeight: Double   // grams per 1 serving
    var nutrientAmounts: [String: Double]   // fdcNumber → amount (only non-zero stored)
    var isArchived: Bool = false    // soft-delete; archived foods stay in cache for ConsumedFood lookups

    var id: Int { customFoodId }

    // MARK: - Codable (custom init so isArchived defaults to false on old JSON)

    enum CodingKeys: String, CodingKey {
        case customFoodId, created, name, servingUnit, servingGramWeight, nutrientAmounts, isArchived
    }

    init(
        customFoodId: Int,
        created: Date = Date(),
        name: String,
        servingUnit: String,
        servingGramWeight: Double,
        nutrientAmounts: [String: Double],
        isArchived: Bool = false
    ) {
        self.customFoodId = customFoodId
        self.created = created
        self.name = name
        self.servingUnit = servingUnit
        self.servingGramWeight = servingGramWeight
        self.nutrientAmounts = nutrientAmounts
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        customFoodId = try c.decode(Int.self, forKey: .customFoodId)
        created = try c.decode(Date.self, forKey: .created)
        name = try c.decode(String.self, forKey: .name)
        servingUnit = try c.decode(String.self, forKey: .servingUnit)
        servingGramWeight = try c.decode(Double.self, forKey: .servingGramWeight)
        nutrientAmounts = try c.decode([String: Double].self, forKey: .nutrientAmounts)
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    // MARK: - Conversions

    func toPortion() -> Portion {
        Portion(name: servingUnit, amount: 1, gramWeight: servingGramWeight)
    }

    func toFoodItem() -> FoodItem {
        let nutrients: [Nutrient] = nutrientAmounts.compactMap { (fdcNumber, amount) in
            guard amount > 0 else { return nil }
            let name = CustomFood.nutrientName(for: fdcNumber) ?? "Nutrient \(fdcNumber)"
            let unit = CustomFood.nutrientUnit(for: fdcNumber)
            return Nutrient(
                fdcId: Int(fdcNumber) ?? 0,
                fdcNumber: fdcNumber,
                name: name,
                unitName: unit,
                amount: amount
            )
        }

        var group = FdcNutrientGroupMapper.makeGroupNutrient(FdcNutrientGroupMapper.GroupNumber_Other)
        group.nutrients = nutrients

        var food = FoodItem(
            fdcId: customFoodId,
            name: name,
            fdcType: "custom",
            nutrientGroups: [group],
            gramWeight: servingGramWeight
        )
        food.amount = 1
        food.portionName = servingUnit
        return food
    }

    // MARK: - Nutrient metadata

    static func nutrientName(for fdcNumber: String) -> String? {
        _nameMap[fdcNumber]
    }

    static func nutrientUnit(for fdcNumber: String) -> String {
        _unitMap[fdcNumber] ?? "g"
    }

    // MARK: - Form fields (ordered, grouped)

    static let formFields: [FormField] = [
        // Macros
        .init(fdcNumber: "208", name: "Calories",          unit: "kcal", group: "Macros"),
        .init(fdcNumber: "203", name: "Protein",           unit: "g",    group: "Macros"),
        .init(fdcNumber: "204", name: "Total Fat",         unit: "g",    group: "Macros"),
        .init(fdcNumber: "205", name: "Carbohydrates",     unit: "g",    group: "Macros"),
        .init(fdcNumber: "291", name: "Fiber",             unit: "g",    group: "Macros"),
        .init(fdcNumber: "269", name: "Sugars",            unit: "g",    group: "Macros"),
        .init(fdcNumber: "307", name: "Sodium",            unit: "mg",   group: "Macros"),
        .init(fdcNumber: "601", name: "Cholesterol",       unit: "mg",   group: "Macros"),
        .init(fdcNumber: "606", name: "Saturated Fat",     unit: "g",    group: "Macros"),
        // Vitamins
        .init(fdcNumber: "320", name: "Vitamin A",         unit: "mcg",  group: "Vitamins"),
        .init(fdcNumber: "401", name: "Vitamin C",         unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "328", name: "Vitamin D",         unit: "mcg",  group: "Vitamins"),
        .init(fdcNumber: "323", name: "Vitamin E",         unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "430", name: "Vitamin K",         unit: "mcg",  group: "Vitamins"),
        .init(fdcNumber: "404", name: "Thiamin (B1)",      unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "405", name: "Riboflavin (B2)",   unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "406", name: "Niacin (B3)",       unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "410", name: "Pantothenic Acid",  unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "415", name: "Vitamin B6",        unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "435", name: "Folate",            unit: "mcg",  group: "Vitamins"),
        .init(fdcNumber: "418", name: "Vitamin B12",       unit: "mcg",  group: "Vitamins"),
        .init(fdcNumber: "421", name: "Choline",           unit: "mg",   group: "Vitamins"),
        .init(fdcNumber: "416", name: "Biotin",            unit: "mcg",  group: "Vitamins"),
        // Minerals
        .init(fdcNumber: "301", name: "Calcium",           unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "303", name: "Iron",              unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "304", name: "Magnesium",         unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "305", name: "Phosphorus",        unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "306", name: "Potassium",         unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "309", name: "Zinc",              unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "312", name: "Copper",            unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "317", name: "Selenium",          unit: "mcg",  group: "Minerals"),
        .init(fdcNumber: "315", name: "Manganese",         unit: "mg",   group: "Minerals"),
        .init(fdcNumber: "314", name: "Iodine",            unit: "mcg",  group: "Minerals"),
        .init(fdcNumber: "310", name: "Chromium",          unit: "mcg",  group: "Minerals"),
        .init(fdcNumber: "316", name: "Molybdenum",        unit: "mcg",  group: "Minerals"),
        .init(fdcNumber: "313", name: "Fluoride",          unit: "mcg",  group: "Minerals"),
        .init(fdcNumber: "354", name: "Boron",             unit: "mcg",  group: "Minerals"),
        // Fatty Acids
        .init(fdcNumber: "605", name: "Trans Fat",         unit: "g",    group: "Fatty Acids"),
        .init(fdcNumber: "645", name: "Monounsaturated Fat", unit: "g",  group: "Fatty Acids"),
        .init(fdcNumber: "646", name: "Polyunsaturated Fat", unit: "g",  group: "Fatty Acids"),
        .init(fdcNumber: "851", name: "Omega-3 ALA",       unit: "g",    group: "Fatty Acids"),
        .init(fdcNumber: "629", name: "Omega-3 EPA",       unit: "g",    group: "Fatty Acids"),
        .init(fdcNumber: "631", name: "Omega-3 DPA",       unit: "g",    group: "Fatty Acids"),
        .init(fdcNumber: "621", name: "Omega-3 DHA",       unit: "g",    group: "Fatty Acids"),
        // Amino Acids
        .init(fdcNumber: "501", name: "Tryptophan",        unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "502", name: "Threonine",         unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "503", name: "Isoleucine",        unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "504", name: "Leucine",           unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "505", name: "Lysine",            unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "506", name: "Methionine",        unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "507", name: "Cystine",           unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "508", name: "Phenylalanine",     unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "509", name: "Tyrosine",          unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "510", name: "Valine",            unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "511", name: "Arginine",          unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "512", name: "Histidine",         unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "513", name: "Alanine",           unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "514", name: "Aspartic Acid",     unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "515", name: "Glutamic Acid",     unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "516", name: "Glycine",           unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "517", name: "Proline",           unit: "g",    group: "Amino Acids"),
        .init(fdcNumber: "518", name: "Serine",            unit: "g",    group: "Amino Acids"),
    ]

    // Additional nutrients available via the "Add Nutrient" picker
    static let otherFields: [FormField] = [
        .init(fdcNumber: "209", name: "Starch",            unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "210", name: "Fructose",          unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "212", name: "Glucose",           unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "213", name: "Sucrose",           unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "211", name: "Galactose",         unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "299", name: "Lactose",           unit: "g",    group: "Carbs & Sugars"),
        .init(fdcNumber: "221", name: "Alcohol",           unit: "g",    group: "Other"),
        .init(fdcNumber: "255", name: "Water",             unit: "g",    group: "Other"),
        .init(fdcNumber: "262", name: "Caffeine",          unit: "mg",   group: "Other"),
        .init(fdcNumber: "263", name: "Theobromine",       unit: "mg",   group: "Other"),
    ]

    struct FormField: Identifiable {
        var id: String { fdcNumber }
        let fdcNumber: String
        let name: String
        let unit: String
        let group: String
    }

    private static let _nameMap: [String: String] = {
        let all = formFields + otherFields
        return Dictionary(uniqueKeysWithValues: all.map { ($0.fdcNumber, $0.name) })
    }()

    private static let _unitMap: [String: String] = {
        let all = formFields + otherFields
        return Dictionary(uniqueKeysWithValues: all.map { ($0.fdcNumber, $0.unit) })
    }()
}
