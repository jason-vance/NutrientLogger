//
//  Portion.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public struct Portion: Hashable, Equatable, Codable {
    
    public static var defaultPortion: Portion { Portion(name: "g", amount: 100, gramWeight: 1) }
    
    public let amount: Double
    public let gramWeight: Double
    public let name: String
    
    public init(name: String = "", amount: Double, gramWeight: Double) {
        self.name = name
        self.amount = amount
        self.gramWeight = gramWeight
    }
}
