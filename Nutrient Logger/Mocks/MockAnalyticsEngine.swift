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

    func log(event: String) {
        loggedEvents.append(("\(event)", [:]))
        print("[Analytics] \(event)")
    }
    
    func log(event: String, parameters: [String : Any]) {
        loggedEvents.append(("\(event)", parameters))
        
        let parameterString = {
            let params = parameters.map { "\($0.key): \($0.value)" }.joined(separator: "\n\t")
            return params.isEmpty ? "" : "\n\t\(params)"
        }()
        
        print("[Analytics] \(event)\(parameterString)")
    }
}
