//
//  RecentSearch.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 1/16/26.
//

import Foundation
import SwiftData

@Model
class RecentSearch {
    var query: String
    var date: Date
    
    init(query: String, date: Date) {
        self.query = query
        self.date = date
    }
}
