//
//  WaistEntry.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import Foundation
import SwiftData

@Model
class WaistEntry: Identifiable {

    @Attribute(.unique) var date: SimpleDate
    var circumferenceCm: Double

    init(date: SimpleDate, circumferenceCm: Double) {
        self.date = date
        self.circumferenceCm = circumferenceCm
    }
}
