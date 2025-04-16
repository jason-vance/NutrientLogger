//
//  ConsumedFoodSaver.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SwinjectAutoregistration

class ConsumedFoodSaverDelegate: FoodSaverDelegate {
    
    public var needsPortion: Bool { true }
    
    public var needsDateTime: Bool { true }
    
    private let db: LocalDatabase
    private let analytics: ConsumedFoodSaverAnalytics?
    
    public init(
        localDatabase: LocalDatabase,
        analytics: ConsumedFoodSaverAnalytics?
    ) {
        self.db = localDatabase
        self.analytics = analytics
    }

    public func saveFoodItem(_ food: FoodItem, _ portion: Portion) throws {
        do {
            let food = try food.applyingPortion(portion)
            try db.saveFoodItem(food)
            analytics?.foodLogged(food)
        } catch {
            print("Error while saving consumed food: \(error.localizedDescription)")
            analytics?.foodLogFailed(food)
            throw error
        }
    }
}

extension FoodSaver {
    static let forConsumedFoods: FoodSaver = FoodSaver(
        delegate: ConsumedFoodSaverDelegate(
            localDatabase: swinjectContainer~>LocalDatabase.self,
            analytics: swinjectContainer~>ConsumedFoodSaverAnalytics.self
        )
    )
}
