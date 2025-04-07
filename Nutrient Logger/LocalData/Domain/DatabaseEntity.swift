//
//  DatabaseEntity.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public protocol DatabaseEntity: Identifiable {
    var id: Int { get set }
    var created: Date { get set }
}

public typealias DatabaseDate = Int64

public extension DatabaseDate {
    static func from(_ date: Date) -> DatabaseDate {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second

        let str = String.init(format: "%d%02d%02d%02d%02d%02d", year!, month!, day!, hour!, minute!, second!)
        return DatabaseDate(str)!
    }
    
    func toDate() -> Date {
        let year = Int(self / 10000000000)
        let month = Int(self / 100000000) % 100
        let day = Int(self / 1000000) % 100
        let hour = Int(self / 10000) % 100
        let minute = Int(self / 100) % 100
        let second = Int(self % 100)
        
        return Date.from(year: year, month: month, day: day, hr: hour, min: minute, sec: second)
    }
}
