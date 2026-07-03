//
//  ActivityLevel.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import Foundation

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extraActive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Light"
        case .moderatelyActive: return "Moderate"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extreme"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .lightlyActive: return "Exercise 1–3 days/week"
        case .moderatelyActive: return "Exercise 3–5 days/week"
        case .veryActive: return "Hard exercise 6–7 days/week"
        case .extraActive: return "Very hard exercise, physical job"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }

    static let appStorageKey = "activityLevel"
}
