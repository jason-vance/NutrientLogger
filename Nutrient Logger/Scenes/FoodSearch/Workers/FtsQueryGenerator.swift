//
//  FtsQueryGenerator.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class FtsQueryGenerator {
    private static let suffixesToTrim = [ "es", "s" ]

    public static func generateFrom(_ query: String) -> String {
        let generated = withoutPunctuation(query)
            .split(separator: " ")
            .map { withoutPluralization($0) }
            .unique()
            .map { withWildcards($0) }
            .joined(separator: " OR ")
        
        return generated
    }
    
    public static func withWildcards<T: StringProtocol>(_ query: T) -> String {
        return query + "*"
    }
    
    public static func withoutPunctuation<T: StringProtocol>(_ query: T) -> String { String(query.filter { !$0.isPunctuation }) }
    
    public static func withoutPluralization<T: StringProtocol>(_ query: T) -> String {
        for suffix in suffixesToTrim {
            if query.lowercased().hasSuffix(suffix) {
                return String(query.prefix(query.count - suffix.count))
            }
        }
        return String(query)
    }
}
