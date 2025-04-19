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
    
    var created: Date = Date.now
    var name: String
    
    @Relationship(deleteRule: .cascade)
    var foodsWithPortions: [FoodWithPortion] = []
    
    public init(name: String) {
        self.name = name
    }
    
    public var foodCount: Int {
        get { foodsWithPortions.count }
    }

    public func equalNameAndFoodCount(_ other: Meal) -> Bool {
        return name == other.name
            && foodCount == other.foodCount
    }

    public var anyFoods: Bool {
        get { !foodsWithPortions.isEmpty }
    }

    public func addFood(_ foodWithPortion: FoodWithPortion) {
        addFoods([ foodWithPortion ])
    }

    public func addFoods(_ foods: [FoodWithPortion]) {
        self.foodsWithPortions.append(contentsOf: foods)
    }

    @Model
    class FoodWithPortion: Equatable {
        
        public var created: Date = Date.now
        
        @Relationship(inverse: \Meal.foodsWithPortions)
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

extension Meal {
    static var sample: Meal {
        let meal = Meal(name: "Sample Meal")
        meal.addFoods(FoodItem.sampleFoods.prefix(3).map { food in
            let portion = Portion(name: food.portionName, amount: food.amount, gramWeight: food.gramWeight)
            return FoodWithPortion(food: food, portion: portion)
        })
        return meal
    }
}
