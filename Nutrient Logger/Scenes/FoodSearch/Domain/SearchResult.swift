//
//  SearchResult.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public struct SearchResult {
    public let items: [SearchResultItem]
    
    public init(_ items: [SearchResultItem]) {
        self.items = items
    }
}

public struct SearchResultItem {
    public let obj: Any
    public let name: String
    public let category: SearchCategory
}
