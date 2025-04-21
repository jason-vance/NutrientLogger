//
//  AdProvider.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/21/25.
//

import Foundation

protocol AdProvider {
    var shouldShowAds: Bool { get }
}

class DefaultAdProvider: AdProvider {
    let shouldShowAds: Bool
    
    init(shouldShowAds: Bool) {
        self.shouldShowAds = shouldShowAds
    }
}
