//
//  DatabaseSimpleDate.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import Foundation

public typealias DatabaseSimpleDate = Int64

public extension DatabaseSimpleDate {
    static func from(_ date: SimpleDate) -> DatabaseSimpleDate {
        return DatabaseSimpleDate(date.rawValue)
    }
    
    func toSimpleDate() -> SimpleDate? {
        return SimpleDate(rawValue: SimpleDate.RawValue(self))
    }
}
