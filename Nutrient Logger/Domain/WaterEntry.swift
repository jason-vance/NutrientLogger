//
//  WaterEntry.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import Foundation
import SwiftData

@Model
class WaterEntry: Identifiable {

    var date: SimpleDate
    var amountGrams: Double

    init(date: SimpleDate, amountGrams: Double) {
        self.date = date
        self.amountGrams = amountGrams
    }
}
