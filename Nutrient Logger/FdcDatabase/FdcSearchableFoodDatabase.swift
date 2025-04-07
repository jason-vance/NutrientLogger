//
//  FdcSearchableFoodDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SQLite

public class FdcSearchableFoodDatabase {
    private enum Errors: Error {
        case ftsTableAlreadyCreated
    }
    
    public let dbPath: String
    
    init(dbPath: URL) async throws {
        self.dbPath = dbPath.path
        try await createFts5Table()
    }
    
    private func createFts5Table() async throws {
        _ = try await Task.init(priority: .userInitiated) {
            let db = try Connection(dbPath)
            try createSearchableFoodTable(db)
        }.value
    }
    
    private func createSearchableFoodTable(_ db: Connection) throws {
        if (searchableFoodTableExists(db)) {
            return
        }
        
        let config = FTS5Config()
            .column(Columns.fdcId)
            .column(Columns.description)
        try db.run(Tables.searchableFood.create(.FTS5(config), ifNotExists: true))
        
        try putAllFoodsIntoSearchableFoods(db)
    }
    
    private func searchableFoodTableExists(_ db: Connection) -> Bool {
        do {
            _ = try db.scalar(Tables.searchableFood.exists)
            return true
        } catch {
            return false
        }
    }
    
    private func putAllFoodsIntoSearchableFoods(_ db: Connection) throws {
        try db.transaction {
            for foodRow in try db.prepare(Tables.food) {
                let food = FoodWrapper(foodRow).food
                let insert = Tables.searchableFood.insert(SearchableFoodWrapper(food).setters)
                try db.run(insert)
            }
        }
    }

    public func search(_ query: String) throws -> [FdcSearchableFood] {
        if query.isEmpty {
            return []
        }
        
        let search = Tables.searchableFood
            .select(Columns.fdcId, Columns.description, Columns.rank)
            .filter(Tables.searchableFood.match(query))
            .order(Columns.rank)

        var results = [FdcSearchableFood]()
        for row in try Connection(dbPath).prepare(search) {
            results.append(SearchableFoodWrapper(row).searchableFood)
        }
        return results
    }

    public func getFood(_ fdcId: Int) throws -> FdcFood? {
        if let foodRow = try Connection(dbPath).pluck(Tables.food.filter(Columns.fdcId == fdcId)) {
            return FoodWrapper(foodRow).food
        }
        return nil
    }

    public func getPortions(_ foodFdcId: Int) throws -> [FdcPortion] {
        var portions = [FdcPortion]()
        for portionRow in try Connection(dbPath).prepare(Tables.portion.filter(Columns.fdcId == foodFdcId)) {
            portions.append(PortionWrapper(portionRow).portion)
        }
        return portions
    }

    public func getNutrientLinks(_ foodFdcId: Int) throws -> [FdcNutrientLink] {
        let query = Tables.nutrientLink
            .select(Columns.id, Columns.fdcId, Columns.nutrientId, Columns.amount)
            .filter(Columns.fdcId == foodFdcId)
            .order(Columns.nutrientId)
        let iterator = try Connection(dbPath).prepareRowIterator(query)
        let rows = try iterator.map { $0 }
        return rows.map {
            NutrientLinkWrapper($0).link
        }
    }

    public func countFoodsContainingNutrients() throws -> [Int:FdcFoodContainingNutrientCount] {
        let query = Tables.nutrientLink
            .select(Columns.fdcId.count, Columns.nutrientId)
            .group(Columns.nutrientId)
        
        var counts = [Int:FdcFoodContainingNutrientCount]()
        for row in try Connection(dbPath).prepare(query) {
            let count = FoodContainingNutrientCountWrapper(row).count
            counts[count.nutrientId] = count
        }
        return counts
    }

    public func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [FdcNutrientFoodPair] {
        let connection = try Connection(dbPath)
        
        let nutrientQuery = Tables.nutrientLink
            .filter(Columns.nutrientId == nutrient.fdcId)
            .where(Columns.amount > 0)
            .order(Columns.amount.desc)
            .limit(500)
        
        var pairs = [FdcNutrientFoodPair]()
        for nutrientRow in try connection.prepare(nutrientQuery) {
            let fdcId = nutrientRow[Columns.fdcId]
            
            if let foodRow = try connection.pluck(Tables.food.filter(Columns.fdcId == fdcId)) {
                let link = NutrientLinkWrapper(nutrientRow).link
                let food = FoodWrapper(foodRow).food
                
                pairs.append(FdcNutrientFoodPair(nutrientLink: link, food: food))
            }
        }
        
        return pairs
    }
}

fileprivate enum Tables {
    public static var searchableFood = VirtualTable("SearchableFood")
    public static var food = Table("Food")
    public static var nutrientLink = Table("Nutrient")
    public static var portion = Table("Portion")
}

fileprivate enum Columns {
    public static var fdcId = Expression<Int>("fdc_id")
    public static var description = Expression<String>("description")
    public static var rank = Expression<Double>("rank")
    public static var dataType = Expression<String>("data_type")
    public static var foodCategoryId = Expression<Int?>("food_category_id")
    public static var id = Expression<Int>("id")
    public static var sequenceNumber = Expression<Int>("seq_num")
    public static var amount = Expression<Double?>("amount")
    public static var amountAsInt = Expression<Int>("amount")
    public static var measureUnitId = Expression<Int>("measure_unit_id")
    public static var portionDescription = Expression<String?>("portion_description")
    public static var modifier = Expression<String?>("modifier")
    public static var gramWeight = Expression<Double?>("gram_weight")
    public static var gramWeightAsInt = Expression<Int>("gram_weight")
    public static var dataPoints = Expression<Int>("data_points")
    public static var footnote = Expression<String>("footnote")
    public static var minYearAquired = Expression<String>("min_year_aquired")
    public static var nutrientId = Expression<Int>("nutrient_id")
    public static var derivationId = Expression<Int>("derivation_id")
    public static var min = Expression<Double>("min")
    public static var max = Expression<Double>("max")
    public static var median = Expression<Double>("median")
}

fileprivate class SearchableFoodWrapper {
    var searchableFood: FdcSearchableFood
    
    init(_ row: Row) {
        self.searchableFood = FdcSearchableFood(
            fdcId: row[Columns.fdcId],
            description: row[Columns.description],
            rank: row[Columns.rank]
        )
    }
    
    init(_ entity: FdcSearchableFood) {
        self.searchableFood = entity
    }
    
    init(_ food: FdcFood) {
        self.searchableFood = FdcSearchableFood(
            fdcId: food.fdcId,
            description: food.description,
            rank: 0
        )
    }
    
    open var setters: [Setter] {
        get { [
            Columns.fdcId <- searchableFood.fdcId,
            Columns.description <- searchableFood.description
        ] }
    }
}

fileprivate class FoodWrapper {
    var food: FdcFood
    
    init(_ row: Row) {
        self.food = FdcFood(
            fdcId: row[Columns.fdcId],
            dataType: row[Columns.dataType],
            description: row[Columns.description],
            foodCategoryId: row[Columns.foodCategoryId]
        )
    }
}

fileprivate class PortionWrapper {
    var portion: FdcPortion
    
    init(_ row: Row) {
        self.portion = FdcPortion(
            id: row[Columns.id],
            fdcId: row[Columns.fdcId],
            sequenceNumber: row[Columns.sequenceNumber],
            amount: row[Columns.amount],
            description: row[Columns.portionDescription],
            modifier: row[Columns.modifier],
            gramWeight: row[Columns.gramWeight] ?? Double(row[Columns.gramWeightAsInt])
        )
    }
}

fileprivate class NutrientLinkWrapper {
    var link: FdcNutrientLink
    
    init(_ row: Row) {
        self.link = FdcNutrientLink(
            id: row[Columns.id],
            fdcId: row[Columns.fdcId],
            nutrientId: row[Columns.nutrientId],
            amount: row[Columns.amount] ?? Double(row[Columns.amountAsInt])
        )
    }
}

fileprivate class FoodContainingNutrientCountWrapper {
    var count: FdcFoodContainingNutrientCount
    
    init(_ row: Row) {
        self.count = FdcFoodContainingNutrientCount(
            count: row[Columns.fdcId.count],
            nutrientId: row[Columns.nutrientId]
        )
    }
}
