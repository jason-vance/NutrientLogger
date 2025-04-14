//
//  Meal.swift
//  Meal
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation

public struct Meal : DatabaseEntity, Identifiable {
    
    public var id: Int = -1
    public var created: Date = Date.now
    public var name: String
    private var foods: [FoodWithPortion] = []
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
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

    public mutating func addFood(_ foodWithPortion: FoodWithPortion) {
        addFoods([ foodWithPortion ])
    }

    public mutating func addFoods(_ foods: [FoodWithPortion]) {
        self.foods.append(contentsOf: foods)
    }

    public var foodPortionPairs: [FoodWithPortion] {
        get { foods }
    }

    public struct FoodWithPortion : DatabaseEntity {
        public var id: Int = -1
        public var created: Date = Date.now
        public var mealId: Int
        public var foodFdcId: Int
        public var foodName: String
        public var portionAmount: Double
        public var portionGramWeight: Double
        public var portionName: String
        
        public init(foodFdcId: Int) {
            self.foodFdcId = foodFdcId
            mealId = -1
            foodName = ""
            portionAmount = 0
            portionGramWeight = 0
            portionName = ""
        }
        
        public init(mealId: Int, foodFdcId: Int, foodName: String, portionAmount: Double, portionGramWeight: Double, portionName: String) {
            self.mealId = mealId
            self.foodFdcId = foodFdcId
            self.foodName = foodName
            self.portionAmount = portionAmount
            self.portionGramWeight = portionGramWeight
            self.portionName = portionName
        }
        
        public func withId(_ id: Int) -> FoodWithPortion {
            var copy = self
            copy.id = id
            return copy
        }
    }
}

public extension Meal {
    
}
