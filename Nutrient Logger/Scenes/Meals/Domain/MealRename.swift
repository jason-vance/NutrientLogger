//
//  MealRename.swift
//  MealRename
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation

public struct MealRename : DatabaseEntity {
    public var id: Int = -1
    public var created: Date = Date.now
    public var mealId: Int
    public var name: String
    
    public init(mealId: Int, name: String) {
        self.mealId = mealId
        self.name = name
    }
}

