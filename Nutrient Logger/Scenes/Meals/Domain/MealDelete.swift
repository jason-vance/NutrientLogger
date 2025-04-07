//
//  MealDelete.swift
//  MealDelete
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation

public struct MealDelete : DatabaseEntity {
    public var id: Int = -1
    public var created: Date = Date.now
    public var mealId: Int
    
    public init(_ mealId: Int) {
        self.mealId = mealId
    }
}

