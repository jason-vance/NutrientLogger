//
//  CsvExportService.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/7/26.
//

import Foundation

struct CsvExportService {

    let remoteDatabase: RemoteDatabase

    private static let nutrientNumbers: [String] = {
        FdcNutrientGroupMapper.nutrientDisplayNames.keys.sorted { lhs, rhs in
            let lhsName = FdcNutrientGroupMapper.nutrientDisplayNames[lhs] ?? lhs
            let rhsName = FdcNutrientGroupMapper.nutrientDisplayNames[rhs] ?? rhs
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }()

    func generateCsv(consumedFoods: [ConsumedFood]) -> String {
        let sortedFoods = consumedFoods.sorted { lhs, rhs in
            if lhs.dateLogged != rhs.dateLogged { return lhs.dateLogged < rhs.dateLogged }
            if lhs.mealTime != rhs.mealTime { return lhs.mealTime < rhs.mealTime }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        var rows: [(consumed: ConsumedFood, nutrients: [String: Double])] = []
        var unitsByNutrientNumber: [String: String] = [:]

        for consumed in sortedFoods {
            var nutrientsByNumber: [String: Double] = [:]

            if let food = try? remoteDatabase.getFood(String(consumed.fdcId)),
               let applied = try? food.applyingPortion(consumed.portion) {
                for nutrient in applied.nutrientGroups.flatMap({ $0.nutrients }) {
                    nutrientsByNumber[nutrient.fdcNumber] = nutrient.amount
                    if unitsByNutrientNumber[nutrient.fdcNumber] == nil {
                        unitsByNutrientNumber[nutrient.fdcNumber] = nutrient.unitName
                    }
                }
            }

            rows.append((consumed, nutrientsByNumber))
        }

        var lines = [headerRow(unitsByNutrientNumber: unitsByNutrientNumber)]
        lines += rows.map { dataRow(for: $0.consumed, nutrients: $0.nutrients) }

        return lines.joined(separator: "\r\n")
    }

    private func headerRow(unitsByNutrientNumber: [String: String]) -> String {
        var fields = ["Date", "Meal", "Food", "Amount", "Portion", "Grams"]
        fields += Self.nutrientNumbers.map { number in
            let name = FdcNutrientGroupMapper.nutrientDisplayNames[number] ?? number
            guard let unit = unitsByNutrientNumber[number] else { return name }
            return "\(name) (\(unit))"
        }
        return fields.map(Self.csvField).joined(separator: ",")
    }

    private func dataRow(for consumed: ConsumedFood, nutrients: [String: Double]) -> String {
        var fields = [
            Self.dateString(consumed.dateLogged),
            consumed.mealTime.rawValue,
            consumed.name,
            Self.formatNumber(consumed.portionAmount),
            consumed.portionName,
            Self.formatNumber(consumed.portionGramWeight),
        ]
        fields += Self.nutrientNumbers.map { number in
            guard let amount = nutrients[number] else { return "" }
            return Self.formatNumber(amount)
        }
        return fields.map(Self.csvField).joined(separator: ",")
    }

    private static func dateString(_ date: SimpleDate) -> String {
        String(format: "%04d-%02d-%02d", date.year, date.month, date.day)
    }

    private static func formatNumber(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private static func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
