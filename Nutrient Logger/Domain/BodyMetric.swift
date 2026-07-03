//
//  BodyMetric.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import Foundation

enum BodyMetric: String, CaseIterable, Identifiable {
    case weight
    case bodyFat
    case bmi
    case waist

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat"
        case .bmi: return "BMI"
        case .waist: return "Waist"
        }
    }

    var hasChart: Bool { self != .bmi }

    static let defaultOrder = "weight,bodyFat,bmi,waist"

    static func ordered(from raw: String) -> [BodyMetric] {
        let parsed = raw.split(separator: ",").compactMap { BodyMetric(rawValue: String($0)) }
        let present = Set(parsed)
        let missing = allCases.filter { !present.contains($0) }
        return parsed + missing
    }
}
