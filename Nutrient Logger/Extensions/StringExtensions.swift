//
//  StringExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/15/25.
//

import Foundation

extension String {
    
    func containsAny(of strs: [any StringProtocol]) -> Bool {
        strs.first { self.contains($0) } != nil
    }
}
