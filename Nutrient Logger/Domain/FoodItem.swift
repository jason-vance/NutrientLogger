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

public class FoodItem: DatabaseEntity, Codable {
    
    public var id: Int = -1
    public var created: Date = Date.now
    public var fdcId: Int = -1
    public var fdcType: String? = nil
    public var name: String
    public var amount: Double = 0
    public var portionName: String = ""
    public var gramWeight: Double = 0
    public var dateLogged: Date = Date.distantPast {
        didSet {
            nutrientGroups.forEach { group in
                group.nutrients.forEach { nutrient in
                    nutrient.dateLogged = dateLogged
                }
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

    public func applyPortion(_ portion: Portion) throws {
        if (self.portion != nil) {
            throw FoodItemError.cannotApplyMultiplePortions
        }

        let multiplier = (portion.amount * portion.gramWeight) / gramWeight

        self.portion = portion
        amount = portion.amount
        portionName = portion.name
        gramWeight = portion.gramWeight
        nutrientGroups = FoodItem.nutrientGroupsWithPortionApplied(nutrientGroups, multiplier)
    }
    
    private static func nutrientGroupsWithPortionApplied(_ nutrientGroups: [NutrientGroup], _ multiplier: Double) -> [NutrientGroup] {
        var rvGroups = [NutrientGroup]()
        
        for group in nutrientGroups {
            group.nutrients = group.nutrients.map { nutrient in
                nutrient.withAmount(nutrient.amount * multiplier)
            }
            rvGroups.append(group)
        }
        
        return rvGroups
    }
}

extension FoodItem: Equatable {
    public static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension FoodItem {
    static let dashboardSample: FoodItem = {
        let sample = FoodItem(name: "Honey")
        sample.amount = 1
        sample.dateLogged = Date()
        sample.portionName = "tbsp"
        return sample
    }()
}
