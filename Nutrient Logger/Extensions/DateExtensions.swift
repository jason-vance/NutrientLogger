//
//  DateExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class TimeConsts {
    public static let secondsPerMinute = 60.0
    public static let minutesPerHour = 60.0
    public static let hoursPerDay = 24.0
    public static let secondsPerHour = minutesPerHour * secondsPerMinute
    public static let secondsPerDay = hoursPerDay * secondsPerHour
}

public extension TimeInterval {
    
    static func fromHours(_ hours: Double) -> TimeInterval {
        return hours * TimeConsts.secondsPerHour
    }
    
    static func fromDays(_ days: Double) -> TimeInterval {
        return days * TimeConsts.secondsPerDay
    }
}

public extension Date {
    
    func relativeDateString(usingClock clock: Clock = SystemClock()) -> String {
        let today = clock.today
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let aboutAWeekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today)!

        if (self >= today) {
            return "Today"
        } else if (self >= yesterday) {
            return "Yesterday"
        } else if (self >= aboutAWeekAgo) {
            return self.toString("EEEE")
        }
        return self.toString("d MMM yyyy")
    }
    
    static func from(year: Int, month: Int, day: Int, hr: Int = 0, min: Int = 0, sec: Int = 0, timeZone: TimeZone? = nil) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone ?? TimeZone.current
        var components = DateComponents(year: year, month: month, day: day, hour: hr, minute: min, second: sec)
        components.timeZone = TimeZone.current
        return calendar.date(from: components)!
    }
    
    func toString(_ format: String, amSymbol: String = "AM", pmSymbol: String = "PM") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.amSymbol = amSymbol
        dateFormatter.pmSymbol = pmSymbol
        return dateFormatter.string(from: self)
    }
    
    var onlyDate: Date {
        get {
            let calender = Calendar.current
            var components = calender.dateComponents([.year, .month, .day], from: self)
            components.timeZone = TimeZone.current
            return calender.date(from: components)!
        }
    }
    
    var timeOfDay: TimeInterval {
        let components = Calendar.current.dateComponents([.second], from: self.onlyDate, to: self)
        if let seconds = components.second {
            return TimeInterval(seconds)
        }
        
        return 0
    }
}
