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
    
    func log(event: String) {
        loggedEvents.append(("\(event)", [:]))
    }
    
    func log(event: String, parameters: [String : Any]) {
        loggedEvents.append(("\(event)", parameters))
    }
}
