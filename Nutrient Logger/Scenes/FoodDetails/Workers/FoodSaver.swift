//
//  FoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

enum FoodSaverErrors: Error {
    case mealIdNotSet
}

protocol FoodSaverDelegate {
    var needsPortion: Bool { get }
    var needsDateTime: Bool { get }
    
    func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws
}

class FoodSaver: ObservableObject {
    var delegate: FoodSaverDelegate
    
    init(delegate: FoodSaverDelegate) {
        self.delegate = delegate
    }
    
    var needsPortion: Bool {
        delegate.needsPortion
    }
    
    var needsDateTime: Bool {
        delegate.needsDateTime
    }
    
    func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws {
        try delegate.saveFoodItem(food, portion)
    }
}
