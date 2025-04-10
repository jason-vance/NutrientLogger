//
//  MockAnalyticsEngine.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import Foundation

class MockAnalyticsEngine: AnalyticsEngine {
    
    var loggedEvents: [(String, [String: Any])] = []

    var eventSearch: String { "eventSearch" }
    
    var parameterSearchTerm: String { "parameterSearchTerm" }
    
    var parameterValue: String { "parameterValue" }
    
    func logEvent(_ event: String) {
        loggedEvents.append(("\(event)", [:]))
    }
    
    func logEvent(_ event: String, withParameters parameters: [String : Any]) {
        loggedEvents.append(("\(event)", parameters))
    }
}
