//
//  Nutrient.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

class Nutrient: DatabaseEntity, Codable, Identifiable {
    
    public var id: Int = -1
    public var created: Date = Date.now
    public let fdcId: Int
    public let fdcNumber: String
    public let name: String
    public var amount: Double
    public let unitName: String
    public var dateLogged: SimpleDate?
    public var mealTime: MealTime?
    
    public init(
        id: Int,
        created: Date,
        fdcId: Int,
        fdcNumber: String,
        name: String,
        amount: Double,
        unitName: String,
        dateLogged: SimpleDate?,
        mealTime: MealTime?
    ) {
        self.id = id
        self.created = created
        self.fdcId = fdcId
        self.fdcNumber = fdcNumber
        self.name = name
        self.amount = amount
        self.unitName = unitName
        self.dateLogged = dateLogged
        self.mealTime = mealTime
    }
    
    public init(fdcId: Int = -1, fdcNumber: String, name: String, unitName: String, amount: Double = 0) {
        self.fdcId = fdcId
        self.fdcNumber = fdcNumber
        self.name = name
        self.unitName = unitName
        self.amount = amount
    }
    
    public func withAmount(_ amount: Double) -> Nutrient {
        return Nutrient(
            id: id,
            created: created,
            fdcId: fdcId,
            fdcNumber: fdcNumber,
            name: name,
            amount: amount,
            unitName: unitName,
            dateLogged: dateLogged,
            mealTime: mealTime
        )
    }
    
    public static func sortNutrients(_ nutrients: [Nutrient]) -> [Nutrient] {
        let byLetterVsNumber = { (lhs: Nutrient, rhs: Nutrient) -> ComparisonResult in
            if (lhs.name.first!.isLetter == rhs.name.first!.isLetter) {
                return ComparisonResult.orderedSame
            }
            return (lhs.name.first!.isLetter) ? ComparisonResult.orderedAscending : ComparisonResult.orderedDescending
        }
        
        let byName = { (lhs: Nutrient, rhs: Nutrient) in
            lhs.name.compare(rhs.name)
        }
        
        return nutrients.sorted(by: byLetterVsNumber, byName)
    }
}

extension Nutrient: Equatable {
    public static func == (lhs: Nutrient, rhs: Nutrient) -> Bool {
        return lhs.id == rhs.id && lhs.fdcId == rhs.fdcId
    }
}
