//
//  ConsumedFoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SwinjectAutoregistration
import SwiftData

class ConsumedFoodSaverDelegate: FoodSaverDelegate {
    
    public var needsPortion: Bool { true }
    
    public var needsDateTime: Bool { true }
    
    private let modelContext: ModelContext
    private let analytics: ConsumedFoodSaverAnalytics?
    
    public init(
        modelContext: ModelContext,
        analytics: ConsumedFoodSaverAnalytics?
    ) {
        self.modelContext = modelContext
        self.analytics = analytics
    }

    public func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws {
        let consumedFood = ConsumedFood(
            fdcId: food.fdcId,
            name: food.name,
            portionAmount: portion.amount,
            portionGramWeight: portion.gramWeight,
            portionName: portion.name,
            dateLogged: food.dateLogged ?? .today,
            mealTime: food.mealTime ?? .none
        )
        modelContext.insert(consumedFood)
        analytics?.foodLogged(food)
    }
}

extension FoodSaver {
    static func forConsumedFoods(modelContext: ModelContext) -> FoodSaver {
        FoodSaver(
            delegate: ConsumedFoodSaverDelegate(
                modelContext: modelContext,
                analytics: swinjectContainer~>ConsumedFoodSaverAnalytics.self
            )
        )
    }
}
