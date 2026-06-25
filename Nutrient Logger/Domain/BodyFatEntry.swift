//
//  BodyFatEntry.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import Foundation
import SwiftData

@Model
class BodyFatEntry: Identifiable {

    @Attribute(.unique) var date: SimpleDate
    var percentage: Double

    init(date: SimpleDate, percentage: Double) {
        self.date = date
        self.percentage = percentage
    }
}
