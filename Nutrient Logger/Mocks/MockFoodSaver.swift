//
//  MockFoodSaver.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

class MockFoodSaverDelegate: FoodSaverDelegate {
    
    public var needsPortion: Bool
    public var needsDateTime: Bool
    
    public var savedFood: FoodItem?
    public var savedPortion: Portion?
    public var errorToThrow: Error?
    
    public init(
        needsPortion: Bool = false,
        needsDateTime: Bool = false
    ) {
        self.needsPortion = needsPortion
        self.needsDateTime = needsDateTime
    }
    
    public func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws {
        if let error = errorToThrow {
            throw error
        }
        
        savedFood = food
        savedPortion = portion
    }
}

extension FoodSaver {
    static let mock: FoodSaver = FoodSaver(delegate: MockFoodSaverDelegate())
}
