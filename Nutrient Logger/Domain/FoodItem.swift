//
//  FoodItem.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

public enum FoodItemError: Error {
    case cannotApplyMultiplePortions
}

struct FoodItem: DatabaseEntity, Codable {
    
    public var id: Int = -1
    public var created: Date = Date.now
    public var fdcId: Int = -1
    public var fdcType: String? = nil
    public var name: String
    public var amount: Double = 0
    public var portionName: String = ""
    public var gramWeight: Double = 0
    public var dateLogged: SimpleDate? {
        didSet {
            nutrientGroups = nutrientGroups.map { group in
                let nutrients = group.nutrients.map { nutrient in
                    var nutrient = nutrient
                    nutrient.dateLogged = dateLogged
                    return nutrient
                }
                return .init(fdcNumber: group.fdcNumber, name: group.name, nutrients: nutrients)
            }
        }
    }
    public var mealTime: MealTime? {
        didSet {
            nutrientGroups = nutrientGroups.map { group in
                let nutrients = group.nutrients.map { nutrient in
                    var nutrient = nutrient
                    nutrient.mealTime = mealTime
                    return nutrient
                }
                return .init(fdcNumber: group.fdcNumber, name: group.name, nutrients: nutrients)
            }
        }
    }
    
    public var nutrientGroups: [NutrientGroup] = []
    
    private var portion: Portion?
    
    public init(fdcId: Int) {
        self.fdcId = fdcId
        self.name = ""
    }
    public init(name: String) {
        self.name = name
    }
    
    public init(fdcId: Int, name: String, fdcType: String?, gramWeight: Double, portionName: String, amount: Double) {
        self.fdcId = fdcId
        self.name = name
        self.fdcType = fdcType
        self.gramWeight = gramWeight
        self.portionName = portionName
        self.amount = amount
    }
    
    public init(fdcId: Int, name: String, fdcType: String, nutrientGroups: [NutrientGroup], gramWeight: Double) {
        self.fdcId = fdcId
        self.name = name
        self.fdcType = fdcType
        self.nutrientGroups = nutrientGroups
        self.gramWeight = gramWeight
    }
    
    public init(nutrientGroups: [NutrientGroup], amount: Double, gramWeight: Double) {
        self.name = ""
        self.nutrientGroups = nutrientGroups
        self.amount = amount
        self.gramWeight = gramWeight
    }

    //TODO: MVP: allow for applying a new portion
    public func applyingPortion(_ portion: Portion) throws -> FoodItem {
        if (self.portion != nil) {
            throw FoodItemError.cannotApplyMultiplePortions
        }

        let multiplier = (portion.amount * portion.gramWeight) / gramWeight

        var food = self
        food.portion = portion
        food.amount = portion.amount
        food.portionName = portion.name
        food.gramWeight = portion.gramWeight
        food.nutrientGroups = FoodItem.nutrientGroupsWithPortionApplied(nutrientGroups, multiplier)
        return food
    }
    
    private static func nutrientGroupsWithPortionApplied(_ nutrientGroups: [NutrientGroup], _ multiplier: Double) -> [NutrientGroup] {
        var rvGroups = [NutrientGroup]()
        
        for group in nutrientGroups {
            let nutrients = group.nutrients.map { nutrient in
                nutrient.withAmount(nutrient.amount * multiplier)
            }
            rvGroups.append(.init(fdcNumber: group.fdcNumber, name: group.name, nutrients: nutrients))
        }
        
        return rvGroups
    }
}

extension FoodItem: Equatable { }

extension FoodItem {
    static let dashboardSample: FoodItem = {
        var sample = FoodItem(name: "Honey")
        sample.dateLogged = .today
        sample.mealTime = .breakfast
        sample.amount = 1
        sample.portionName = "tbsp"
        return sample
    }()
}
