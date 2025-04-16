//
//  Meal.swift
//  Meal
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation
import SwiftData

@Model
class Meal: Identifiable {
    
    public var created: Date = Date.now
    public var name: String
    
    @Relationship(deleteRule: .cascade)
    private var foods: [FoodWithPortion] = []
    
    public init(name: String) {
        self.name = name
    }
    
    public var foodCount: Int {
        get { foods.count }
    }

    public func equalNameAndFoodCount(_ other: Meal) -> Bool {
        return name == other.name
            && foodCount == other.foodCount
    }

    public var anyFoods: Bool {
        get { !foods.isEmpty }
    }

    public func addFood(_ foodWithPortion: FoodWithPortion) {
        addFoods([ foodWithPortion ])
    }

    public func addFoods(_ foods: [FoodWithPortion]) {
        self.foods.append(contentsOf: foods)
    }

    public var foodPortionPairs: [FoodWithPortion] {
        get { foods }
    }

    @Model
    class FoodWithPortion: Equatable {
        
        public var created: Date = Date.now
        
        @Relationship(inverse: \Meal.foods)
        public var meal: Meal?
        
        public var foodFdcId: Int
        public var foodName: String
        public var portionAmount: Double
        public var portionGramWeight: Double
        public var portionName: String
        
        public init(foodFdcId: Int) {
            self.foodFdcId = foodFdcId
            foodName = ""
            portionAmount = 0
            portionGramWeight = 0
            portionName = ""
        }
        
        public init(foodFdcId: Int, foodName: String, portionAmount: Double, portionGramWeight: Double, portionName: String) {
            self.foodFdcId = foodFdcId
            self.foodName = foodName
            self.portionAmount = portionAmount
            self.portionGramWeight = portionGramWeight
            self.portionName = portionName
        }
        
        init(food: FoodItem, portion: Portion) {
            self.foodFdcId = food.fdcId
            self.foodName = food.name
            self.portionAmount = portion.amount
            self.portionGramWeight = portion.gramWeight
            self.portionName = portion.name
        }
    }
}

extension Meal: Equatable { }
