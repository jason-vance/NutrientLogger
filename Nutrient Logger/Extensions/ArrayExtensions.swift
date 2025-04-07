//
//  ArrayExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

extension Array where Element: Equatable {
    func unique() -> [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}
