//
//  FoodDelete.swift
//  FoodDelete
//
//  Created by Jason Vance on 8/22/21.
//

import Foundation

public struct FoodDelete : DatabaseEntity {
    public var id: Int = -1
    public var created: Date = Date.now
    public var foodId: Int
    
    public init(_ foodId: Int) {
        self.foodId = foodId
    }
}
