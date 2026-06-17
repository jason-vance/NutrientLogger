//
//  Clock.swift
//  Clock
//
//  Created by Jason Vance on 8/6/21.
//

import Foundation

public protocol AppClock {
    var today: Date { get }
    var now: Date { get }
}

public class SystemClock : AppClock {
    public init() {}
    
    public var today: Date {
        return Calendar.current.startOfDay(for: now)
    }
    
    public var now: Date {
        return Date.now
    }
}

public class MutableClock : AppClock {
    public init() {}
    
    public var today: Date {
        return Calendar.current.startOfDay(for: now)
    }
    
    public var now: Date = Date.now
}
