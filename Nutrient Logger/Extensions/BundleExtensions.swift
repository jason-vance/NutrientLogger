//
//  BundleExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/20/25.
//

import Foundation

extension Bundle {
    
    var appName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ?? infoDictionary?["CFBundleName"] as? String ?? "Nutrient Logger"
    }
    
    var version: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
    
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}
