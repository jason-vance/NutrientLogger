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
    
    init(date: Date, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}
