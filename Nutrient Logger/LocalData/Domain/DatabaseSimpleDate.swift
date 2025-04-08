//
//  DatabaseSimpleDate.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import Foundation

typealias DatabaseSimpleDate = Int64

extension DatabaseSimpleDate {
    static func from(_ date: SimpleDate) -> DatabaseSimpleDate {
        return DatabaseSimpleDate(date)
    }
    
    func toSimpleDate() -> SimpleDate? {
        return SimpleDate(rawValue: SimpleDate(self))
    }
}
