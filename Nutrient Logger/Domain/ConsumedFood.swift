//
//  ConsumedFood.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import Foundation
import SwiftData

@Model
class ConsumedFood: Identifiable {
    
    var created: Date = Date()
    var fdcId: Int
    var name: String
    var portionAmount: Double
    var portionGramWeight: Double
    var portionName: String
    var dateLogged: SimpleDate
    var mealTime: MealTime
    
    init(
        fdcId: Int,
        name: String,
        portionAmount: Double,
        portionGramWeight: Double,
        portionName: String,
        dateLogged: SimpleDate,
        mealTime: MealTime
    ) {
        self.fdcId = fdcId
        self.name = name
        self.portionAmount = portionAmount
        self.portionGramWeight = portionGramWeight
        self.portionName = portionName
        self.dateLogged = dateLogged
        self.mealTime = mealTime
    }
    
    init(
        foodItem: FoodItem,
        portion: Portion,
        dateLogged: SimpleDate,
        mealTime: MealTime
    ) {
        self.fdcId = foodItem.fdcId
        self.name = foodItem.name
        self.portionAmount = portion.amount
        self.portionGramWeight = portion.gramWeight
        self.portionName = portion.name
        self.dateLogged = dateLogged
        self.mealTime = mealTime
    }
    
    var portion: Portion {
        Portion(
            name: portionName,
            amount: portionAmount,
            gramWeight: portionGramWeight
        )
    }
}

extension ConsumedFood {
    static let dashboardSample: ConsumedFood = .init(
        fdcId: 1234,
        name: "Honey",
        portionAmount: 1.0,
        portionGramWeight: 100,
        portionName: "tbsp",
        dateLogged: .today,
        mealTime: .breakfast
    )
}
