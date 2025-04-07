//
//  NutrientGroup.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public class NutrientGroup: Codable {
    public var fdcNumber: String
    public var name: String
    public var rank: Int
    public var nutrients: [Nutrient]
    
    public init(fdcNumber: String, name: String, nutrients: [Nutrient]) {
        self.fdcNumber = fdcNumber
        self.name = name
        self.nutrients = nutrients
        rank = 0
    }
    
    public init(fdcNumber: String, name: String, rank: Int) {
        self.fdcNumber = fdcNumber
        self.name = name
        self.rank = rank
        nutrients = []
    }
}
