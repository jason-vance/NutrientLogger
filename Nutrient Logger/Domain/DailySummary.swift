//
//  DailySummary.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 1/16/26.
//

import Foundation
import SwiftData

@Model
class DailySummary: Identifiable {
    
    @Attribute(.unique) var date: Date
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var waterGrams: Double = 0

    init(date: Date, calories: Double, protein: Double, carbs: Double, fat: Double, waterGrams: Double = 0) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.waterGrams = waterGrams
    }
}
