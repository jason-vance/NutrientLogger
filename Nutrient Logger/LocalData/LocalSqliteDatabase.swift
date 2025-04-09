//
//  LocalSqliteDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SQLite

class LocalSqliteDatabase: LocalDatabase {
    
    private var dbName: String { "data.db" }
    private var dbDir: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
    private var dbPath: String { dbDir.appendingPathComponent(dbName).path }
    
    public private(set) var hasDataChanged: Bool = false
    
    public init() throws {
        try createTables()
    }
    
    private func createTables() throws {
        let path = dbPath
        let db = try Connection(path)
        
        try createFoodItemTable(db)
        try createNutrientTable(db)
        try createFoodNutrientLinkTable(db)
        try createDeletedFoodTable(db)
    }
    
    private func createFoodItemTable(_ db: Connection) throws {
        try db.run(Tables.foodItem.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.fdcId)
            t.column(Columns.fdcType)
            t.column(Columns.name)
            t.column(Columns.amount)
            t.column(Columns.portionName)
            t.column(Columns.gramWeight)
            t.column(Columns.dateLogged)
        })
    }
    
    private func createNutrientTable(_ db: Connection) throws {
        try db.run(Tables.nutrient.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.fdcId)
            t.column(Columns.fdcNumber)
            t.column(Columns.name)
            t.column(Columns.amount)
            t.column(Columns.unitName)
            t.column(Columns.dateLogged)
        })
    }
    
    private func createFoodNutrientLinkTable(_ db: Connection) throws {
        try db.run(Tables.foodNutrientLink.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.foodId)
            t.column(Columns.nutrientId)
        })
    }
    
    private func createDeletedFoodTable(_ db: Connection) throws {
        try db.run(Tables.deletedFood.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.foodId)
        })
    }
    
    public func resetHasDataChanged() {
        hasDataChanged = false
    }
    
    public func saveFoodItem(_ food: FoodItem) throws {
        let db = try Connection(dbPath)
        
        let foodWrapper = FoodItemWrapper(food)
        let foodInsert = Tables.foodItem.insert(foodWrapper.setters)
        let foodId = try db.run(foodInsert)
        for group in food.nutrientGroups {
            for nutrient in group.nutrients {
                if (nutrient.amount == 0) {
                    continue
                }
                
                let nutrientWrapper = NutrientWrapper(nutrient)
                let nutrientInsert = Tables.nutrient.insert(nutrientWrapper.setters)
                let nutrientId = try db.run(nutrientInsert)
                
                let link = FoodNutrientLink(foodId: Int(foodId), nutrientId: Int(nutrientId))
                let linkWrapper = FoodNutrientLinkWrapper(link)
                let linkInsert = Tables.foodNutrientLink.insert(linkWrapper.setters)
                try db.run(linkInsert)
            }
        }
        
        hasDataChanged = true
    }
    
    public func getFoodsOrderedByDateLogged(_ date: SimpleDate) throws -> [FoodItem] {
        let date = DatabaseDate.from(date)
        
        let db = try Connection(dbPath)
        
        let foodQuery = Tables.foodItem
            .where(Columns.dateLogged == date)
            .order(Columns.dateLogged)
        let foodRows = try db.prepare(foodQuery)
        var foods = foodRows.map { FoodItemWrapper($0).food }
        
        try removeDeletedFoods(db, &foods)
        
        return try foods.map {
            var food = $0
            food.nutrientGroups = try getAbridgedNutrients(db, food)
            return food
        }
    }
    
    private func getAbridgedNutrients(_ db: Connection, _ food: FoodItem) throws -> [NutrientGroup] {
        let query = Tables.nutrient
            .join(Tables.foodNutrientLink,
                  on: Tables.nutrient[Columns.id] == Tables.foodNutrientLink[Columns.nutrientId])
            .select(
                Tables.nutrient[Columns.fdcNumber],
                Tables.nutrient[Columns.name],
                Tables.nutrient[Columns.unitName],
                Tables.nutrient[Columns.amount])
            .where(Columns.foodId == food.id)
        
        let rows = try db.prepare(query)
        let nutrients = rows.map { NutrientWrapper.fromAbridged($0) }
        return FdcNutrientGrouper.group(nutrients)
    }
    
    private func getFullNutrients(_ db: Connection, _ food: FoodItem) throws -> [NutrientGroup] {
        let query = Tables.nutrient
            .join(Tables.foodNutrientLink,
                  on: Tables.nutrient[Columns.id] == Tables.foodNutrientLink[Columns.nutrientId])
            .select(
                Tables.nutrient[Columns.fdcId],
                Tables.nutrient[Columns.fdcNumber],
                Tables.nutrient[Columns.name],
                Tables.nutrient[Columns.unitName],
                Tables.nutrient[Columns.amount],
                Tables.nutrient[Columns.id],
                Tables.nutrient[Columns.created],
                Tables.nutrient[Columns.dateLogged])
            .where(Columns.foodId == food.id)
        
        let rows = try db.prepare(query)
        let nutrients = rows.map { NutrientWrapper.fromFull($0) }
        return FdcNutrientGrouper.group(nutrients)
    }
    
    private func removeDeletedFoods(_ db: Connection, _ foods: inout [FoodItem]) throws {
        foods = foods.filter { food in
            let deleteds = Tables.deletedFood.where(Columns.foodId == food.id)
            do {
                let count = try db.scalar(deleteds.count)
                return count == 0
            } catch { }
            return true
        }
    }
    
    public func deleteFood(_ food: FoodItem) throws {
        let deletedFood = DeletedFood(foodId: food.id)
        let wrapper = DeletedFoodWrapper(deletedFood)
        let insert = Tables.deletedFood.insert(wrapper.setters)
        try Connection(dbPath).run(insert)
        hasDataChanged = true
    }
    
    public func getFood(_ id: Int) throws -> FoodItem? {
        let query = Tables.foodItem
            .where(Columns.id == id)
        
        let db = try Connection(dbPath)
        if let row = try db.pluck(query) {
            var food = FoodItemWrapper(row).food
            food.nutrientGroups = try getFullNutrients(db, food)
            return food
        }
        
        return nil
    }
    
    public func getEarliestFood() throws -> FoodItem? {
        return try getLeastOrMostRecentFood(false)
    }
    
    public func getMostRecentFood() throws -> FoodItem? {
        return try getLeastOrMostRecentFood(true)
    }
    
    private func getLeastOrMostRecentFood(_ mostRecent: Bool) throws -> FoodItem? {
        let query = Tables.foodItem
            .order(mostRecent ? Columns.created.desc : Columns.created.asc)
        
        let db = try Connection(dbPath)
        if let row = try db.pluck(query) {
            return FoodItemWrapper(row).food
        }
        
        return nil
    }
    
    public func getRecentlyLoggedFoods(_ limit: Int) throws -> [FoodItem] {
        let query = Tables.foodItem
            .select(Columns.created.max,
                    Columns.id,
                    Columns.created,
                    Columns.fdcId,
                    Columns.fdcType,
                    Columns.name,
                    Columns.amount,
                    Columns.portionName,
                    Columns.gramWeight,
                    Columns.dateLogged)
            .group(Columns.fdcId)
            .order(Columns.created.desc)
            .limit(limit)
        
        let db = try Connection(dbPath)
        let rows = try db.prepare(query)
        
        return rows.map { FoodItemWrapper($0).food }
    }
}

fileprivate enum Tables {
    public static var foodItem = Table("FoodItem")
    public static var nutrient = Table("Nutrient")
    public static var foodNutrientLink = Table("FoodNutrientLink")
    public static var deletedFood = Table("DeletedFood")
}

fileprivate enum Columns {
    public static var id = Expression<Int>("Id")
    public static var created = Expression<DatabaseDate>("Created")
    public static var fdcId = Expression<Int>("FdcId")
    public static var fdcType = Expression<String?>("FdcType")
    public static var name = Expression<String>("Name")
    public static var amount = Expression<Double>("Amount")
    public static var portionName = Expression<String>("PortionName")
    public static var gramWeight = Expression<Double>("GramWeight")
    public static var dateLogged = Expression<DatabaseSimpleDate>("DateLogged")
    public static var fdcNumber = Expression<String>("FdcNumber")
    public static var unitName = Expression<String>("UnitName")
    public static var foodId = Expression<Int>("FoodId")
    public static var nutrientId = Expression<Int>("NutrientId")
}

fileprivate class DatabaseEntityWrapper<Entity: DatabaseEntity> {
    var entity: Entity
    
    init(_ row: Row, _ entity: Entity) {
        self.entity = entity
        
        self.entity.id = row[Columns.id]
        self.entity.created = row[Columns.created].toDate()
    }
    
    init(_ entity: Entity) {
        self.entity = entity
    }
    
    open var setters: [Setter] {
        get { [ Columns.created <- DatabaseDate.from(entity.created) ] }
    }
}

fileprivate class FoodItemWrapper: DatabaseEntityWrapper<FoodItem> {
    var food: FoodItem {
        get { entity }
    }
    
    init(_ row: Row) {
        var food = FoodItem(
            fdcId: row[Columns.fdcId],
            name: row[Columns.name],
            fdcType: row[Columns.fdcType],
            gramWeight: row[Columns.gramWeight],
            portionName: row[Columns.portionName],
            amount: row[Columns.amount]
        )
        food.dateLogged = row[Columns.dateLogged].toSimpleDate()
        
        super.init(row, food)
    }
    
    override init(_ food: FoodItem) {
        super.init(food)
    }
    
    override var setters: [Setter] {
        get { super.setters + [
            Columns.fdcId <- food.fdcId,
            Columns.fdcType <- food.fdcType,
            Columns.name <- food.name,
            Columns.amount <- food.amount,
            Columns.portionName <- food.portionName,
            Columns.gramWeight <- food.gramWeight,
            //TODO: MVP: Is .today appropriate here
            Columns.dateLogged <- DatabaseSimpleDate.from(food.dateLogged ?? .today)
        ] }
    }
}

fileprivate class NutrientWrapper: DatabaseEntityWrapper<Nutrient> {
    var nutrient: Nutrient {
        get { entity }
    }
    
    init(_ row: Row) {
        let nutrient = Nutrient(
            fdcId: row[Columns.fdcId],
            fdcNumber: row[Columns.fdcNumber],
            name: row[Columns.name],
            unitName: row[Columns.unitName],
            amount: row[Columns.amount]
        )
        nutrient.dateLogged = row[Columns.dateLogged].toSimpleDate()
        
        super.init(row, nutrient)
    }
    
    //TODO: MVP: Make sure this still works
    static func fromAbridged(_ row: Row) -> Nutrient {
        let nutrient = Nutrient(
            fdcNumber: try! row.get(Columns.fdcNumber),
            name: try! row.get(Columns.name),
            unitName: try! row.get(Columns.unitName),
            amount: try! row.get(Columns.amount)
        )
        return nutrient
    }
    
    //TODO: MVP: Make sure this still works
    static func fromFull(_ row: Row) -> Nutrient {
        let nutrient = Nutrient(
            fdcId: try! row.get(Columns.fdcId),
            fdcNumber: try! row.get(Columns.fdcNumber),
            name: try! row.get(Columns.name),
            unitName: try! row.get(Columns.unitName),
            amount: try! row.get(Columns.amount)
        )
        nutrient.id = try! row.get(Columns.id)
        nutrient.created = try! row.get(Columns.created).toDate()
        nutrient.dateLogged = try! row.get(Columns.dateLogged).toSimpleDate()
        return nutrient
    }
    
    override init(_ nutrient: Nutrient) {
        super.init(nutrient)
    }
    
    override var setters: [Setter] {
        get { super.setters + [
            Columns.fdcId <- nutrient.fdcId,
            Columns.fdcNumber <- nutrient.fdcNumber,
            Columns.name <- nutrient.name,
            Columns.amount <- nutrient.amount,
            Columns.unitName <- nutrient.unitName,
            //TODO: MVP: Is .today appropriate here
            Columns.dateLogged <- DatabaseSimpleDate.from(nutrient.dateLogged ?? .today)
        ] }
    }
}

fileprivate class DeletedFoodWrapper: DatabaseEntityWrapper<DeletedFood> {
    var deletedFood: DeletedFood {
        get { entity }
    }
    
    init(_ row: Row) {
        let deletedFood = DeletedFood(foodId: row[Columns.foodId])
        super.init(row, deletedFood)
    }
    
    override init(_ deletedFood: DeletedFood) {
        super.init(deletedFood)
    }
    
    override var setters: [Setter] {
        get { super.setters + [
            Columns.foodId <- deletedFood.foodId
        ] }
    }
}

fileprivate class FoodNutrientLinkWrapper: DatabaseEntityWrapper<FoodNutrientLink> {
    var foodNutrientLink: FoodNutrientLink {
        get { entity }
    }
    
    init(_ row: Row) {
        let foodNutrientLink = FoodNutrientLink(
            foodId: row[Columns.foodId],
            nutrientId: row[Columns.nutrientId]
        )
        super.init(row, foodNutrientLink)
    }
    
    override init(_ foodNutrientLink: FoodNutrientLink) {
        super.init(foodNutrientLink)
    }
    
    override var setters: [Setter] {
        get { super.setters + [
            Columns.foodId <- foodNutrientLink.foodId,
            Columns.nutrientId <- foodNutrientLink.nutrientId
        ] }
    }
}

