//
//  FirebaseAnalytics.swift
//  FirebaseAnalytics
//
//  Created by Jason Vance on 4/19/25.
//

import Foundation
import FirebaseAnalytics

class FirebaseAnalytics: AnalyticsEngine {
    
    public var eventSearch: String { AnalyticsEventSearch }
    
    public var parameterSearchTerm: String { AnalyticsParameterSearchTerm }
    
    public var parameterValue: String { AnalyticsParameterValue }
    
    public func log(event: String) {
        Analytics.logEvent(event, parameters: nil)
    }
    
    public func log(event: String, parameters: [String : Any]) {
        Analytics.logEvent(event, parameters: parameters)
    }
}
