//
//  WeightEntry.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import Foundation
import SwiftData

@Model
class WeightEntry: Identifiable {

    @Attribute(.unique) var date: SimpleDate
    var weightKg: Double

    init(date: SimpleDate, weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }
}
