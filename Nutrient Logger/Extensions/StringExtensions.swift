//
//  StringExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/15/25.
//

import Foundation

extension String {
    
    func caseInsensitiveContainsAny(of strs: [any StringProtocol]) -> Bool {
        strs.first { self.localizedCaseInsensitiveContains($0) } != nil
    }
}
