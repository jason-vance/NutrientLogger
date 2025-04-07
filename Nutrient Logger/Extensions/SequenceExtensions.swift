//
//  SequenceExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public extension Sequence {
    func sorted(by predicates: ((Element, Element) -> ComparisonResult)..., order: SortOrder = SortOrder.forward) -> [Element] {
        sorted { valueA, valueB in
            for predicate in predicates {
                let result = predicate(valueA, valueB)

                switch result {
                case .orderedSame:
                    // Keep iterating if the two elements are equal,
                    // since that'll let the next descriptor determine
                    // the sort order:
                    break
                case .orderedAscending:
                    return order == .forward
                case .orderedDescending:
                    return order == .reverse
                }
            }

            // If no descriptor was able to determine the sort
            // order, we'll default to false (similar to when
            // using the '<' operator with the built-in API):
            return false
        }
    }
}
