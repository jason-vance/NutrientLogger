//
//  FdcSupportingDataDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SQLite

public class FdcSupportingDataDatabase {
    public let dbPath: String
    
    init(dbPath: URL) throws {
        self.dbPath = dbPath.path
    }
    
    public func getNutrients(_ nutrientLinks: [FdcNutrientLink]) throws -> [FdcNutrientLink:FdcNutrient] {
        var rv = [FdcNutrientLink:FdcNutrient]()
        for link in nutrientLinks {
            if let row = try Connection(dbPath).pluck(Tables.nutrient.filter(Columns.id == link.nutrientId)) {
                rv[link] = NutrientWrapper(row).nutrient
            }
        }
        return rv
    }

    public func getAllNutrients() throws -> [FdcNutrient] {
        var nutrients = [FdcNutrient]()
        for row in try Connection(dbPath).prepare(Tables.nutrient) {
            nutrients.append(NutrientWrapper(row).nutrient)
        }
        return nutrients
    }

    public func getNutrient(_ nutrientNumber: String) throws -> FdcNutrient? {
        if let row = try Connection(dbPath).pluck(Tables.nutrient.filter(Columns.nutrientNumber == nutrientNumber)) {
            return NutrientWrapper(row).nutrient
        }
        return nil
    }
    
}

fileprivate enum Tables {
    public static var nutrient = Table("Nutrient")
}

fileprivate enum Columns {
    public static var id = Expression<Int>("id")
    public static var name = Expression<String>("name")
    public static var unitName = Expression<String>("unit_name")
    public static var nutrientNumber = Expression<String>("nutrient_nbr")
    public static var nutrientNumberAsDouble = Expression<Double>("nutrient_nbr")
}

fileprivate class NutrientWrapper {
    public let nutrient: FdcNutrient
    
    public init(_ row: Row) {
        var nutrientNumber = String(format: "%.1f", row[Columns.nutrientNumberAsDouble])
        if (nutrientNumber.hasSuffix(".0")) {
            nutrientNumber = String(nutrientNumber.prefix { $0 != "." })
        }
        
        nutrient = FdcNutrient(
            id: row[Columns.id],
            name: row[Columns.name],
            unitName: row[Columns.unitName],
            nutrientNumber: nutrientNumber
        )
    }
}
