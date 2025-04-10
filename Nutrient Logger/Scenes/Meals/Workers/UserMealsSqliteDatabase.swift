//
//  UserMealsSqliteDatabase.swift
//  UserMealsSqliteDatabase
//
//  Created by Jason Vance on 9/17/21.
//

import Foundation
import SQLite

public class UserMealsSqliteDatabase: UserMealsDatabase {
    public enum Errors: Error {
        case noSuchRecord
    }
    
    private var dbName: String { "meals.db" }
    private var dbDir: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
    private var dbPath: String { dbDir.appendingPathComponent(dbName).path }
    
    required init() async throws {
        try await createTables()
    }

    private func createTables() async throws {
        let path = dbPath
        let db = try Connection(path)
        
        try createMealTable(db)
        try createFoodWithPortionTable(db)
        try createMealRenameTable(db)
        try createMealDeleteTable(db)
        try createFoodDeleteTable(db)
        try await createFts5Table(db)
    }
    
    private func createFts5Table(_ db: Connection) async throws {
        _ = try await Task.init(priority: .userInitiated) {
            try createSearchableMealTable(db)
        }.value
    }
    
    private func createSearchableMealTable(_ db: Connection) throws {
        if (searchableMealTableExists(db)) {
            return
        }
        
        let config = FTS5Config()
            .column(Columns.mealId)
            .column(Columns.foodId)
            .column(Columns.mealName)
            .column(Columns.foodName)
        try db.run(Tables.searchableMeal.create(.FTS5(config), ifNotExists: true))
        
        try putAllMealsAndFoodsIntoSearchableMeal(db)
    }
    
    private func searchableMealTableExists(_ db: Connection) -> Bool {
        do {
            _ = try db.scalar(Tables.searchableMeal.exists)
            return true
        } catch {
            return false
        }
    }
    
    private func putAllMealsAndFoodsIntoSearchableMeal(_ db: Connection) throws {
        let menu = try getMenu()
        
        try db.transaction {
            for meal in menu.meals {
                let insert = Tables.searchableMeal.insert(SearchableMealWrapper(meal, nil).setters)
                try db.run(insert)
                
                let foods = try getFoods(withMealId: meal.id, db)
                for food in foods {
                    let insert = Tables.searchableMeal.insert(SearchableMealWrapper(meal, food).setters)
                    try db.run(insert)
                }
            }
        }
    }
    
    private func createMealTable(_ db: Connection) throws {
        try db.run(Tables.meal.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.name)
        })
    }
    
    private func createFoodWithPortionTable(_ db: Connection) throws {
        try db.run(Tables.foodWithPortion.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.mealId)
            t.column(Columns.foodFdcId)
            t.column(Columns.foodName)
            t.column(Columns.portionAmount)
            t.column(Columns.portionGramWeight)
            t.column(Columns.portionName)
        })
    }
    
    private func createMealRenameTable(_ db: Connection) throws {
        try db.run(Tables.mealRename.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.mealId)
            t.column(Columns.name)
        })
    }
    
    private func createMealDeleteTable(_ db: Connection) throws {
        try db.run(Tables.mealDelete.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.mealId)
        })
    }
    
    private func createFoodDeleteTable(_ db: Connection) throws {
        try db.run(Tables.foodDelete.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: .autoincrement)
            t.column(Columns.created)
            t.column(Columns.foodId)
        })
    }
    
    public func search(_ query: String) throws -> [UserMealsSearchableMeal] {
        if query.isEmpty { return [] }
        
        let ftsQuery = FtsQueryGenerator.generateFrom(query)

        let search = Tables.searchableMeal
            .select(
                Columns.mealId,
                Columns.foodId,
                Columns.mealName,
                Columns.foodName,
                Columns.rank)
            .filter(Tables.searchableMeal.match(ftsQuery))
            .group(Columns.mealId)
            .order(Columns.rank)
            
        let db = try Connection(dbPath)
        return try db.prepare(search)
            .map { SearchableMealWrapper($0).searchableMeal }
            .filter { !isMealDeleted(db, $0.mealId) }
            .filter { !isFoodDeleted(db, $0.foodId) }
            .map { applyCurrentName(db, $0) }
    }
    
    private func applyCurrentName(_ db: Connection, _ meal: UserMealsSearchableMeal) -> UserMealsSearchableMeal {
        var rvMeal = meal
        
        do {
            let mealRenames = Tables.mealRename
                .where(Columns.mealId == meal.mealId)
                .order(Columns.created.desc)
                .limit(1)
            
            if let rename = try db.pluck(mealRenames) {
                rvMeal.mealName = rename[Columns.name]
            }
        } catch  {}
        
        return rvMeal
    }
    
    public func getMenu() throws -> Menu {
        let menu = Menu()
        menu.add(try getMeals())
        return menu
    }
    
    private func getMeals() throws -> [Meal] {
        let db = try Connection(dbPath)
        
        var meals = [Meal]()
        for mealRow in try db.prepare(Tables.meal) {
            let wrapped = MealWrapper(mealRow)
            meals.append(wrapped.meal)
        }

        return meals
            .filter { !isMealDeleted(db, $0.id) }
            .map { applyCurrentName(db, $0) }
    }
    
    private func isMealDeleted(_ db: Connection, _ mealId: Int) -> Bool {
        let deleteds = Tables.mealDelete.where(Columns.mealId == mealId)
        do {
            let count = try db.scalar(deleteds.count)
            return count > 0
        } catch { }
        return false
    }
    
    public func saveMeal(_ meal: Meal) throws {
        let db = try Connection(dbPath)
        
        let wrapper = MealWrapper(meal)
        let insert = Tables.meal.insert(wrapper.setters)
        let mealId = try db.run(insert)
        
        let searchWrapper = SearchableMealWrapper(meal, nil)
        searchWrapper.searchableMeal.mealId = Int(mealId)
        let searchInsert = Tables.searchableMeal.insert(searchWrapper.setters)
        try db.run(searchInsert)
    }
    
    public func getMeal(_ id: Int) throws -> Meal {
        let db = try Connection(dbPath)
        
        if let mealRow = try db.pluck(Tables.meal.filter(Columns.id == id)) {
            var meal = MealWrapper(mealRow).meal
            
            meal = applyCurrentName(db, meal)
            
            let foods = try getFoods(withMealId: id, db)
            meal.addFoods(foods)
            
            return meal
        } else {
            throw Errors.noSuchRecord
        }
    }
    
    private func getFoods(withMealId mealId: Int, _ db: Connection) throws -> [Meal.FoodWithPortion] {
        let foodRows = try db.prepare(Tables.foodWithPortion.filter(Columns.mealId == mealId))
        let foods = FoodWithPortionWrapper.from(foodRows)
            .filter { !isFoodDeleted(db, $0.id) }
        return foods
    }
    
    private func isFoodDeleted(_ db: Connection, _ foodId: Int) -> Bool {
        let deleteds = Tables.foodDelete.where(Columns.foodId == foodId)
        do {
            let count = try db.scalar(deleteds.count)
            return count > 0
        } catch { }
        return false
    }

    private func applyCurrentName(_ db: Connection, _ meal: Meal) -> Meal {
        var rvMeal = meal
        
        do {
            let mealRenames = Tables.mealRename
                .where(Columns.mealId == meal.id)
                .order(Columns.created.desc)
                .limit(1)
            
            if let rename = try db.pluck(mealRenames) {
                rvMeal.name = rename[Columns.name]
            }
        } catch  {}
        
        return rvMeal
    }
    
    public func saveFood(_ mealFood: Meal.FoodWithPortion, _ meal: Meal) throws {
        let db = try Connection(dbPath)
        
        let wrapper = FoodWithPortionWrapper(mealFood)
        let insert = Tables.foodWithPortion.insert(wrapper.setters)
        let foodId = try db.run(insert)
        
        let searchWrapper = SearchableMealWrapper(meal, mealFood)
        searchWrapper.searchableMeal.foodId = Int(foodId)
        let searchInsert = Tables.searchableMeal.insert(searchWrapper.setters)
        try db.run(searchInsert)
    }
    
    public func saveMealRename(_ mealRename: MealRename) throws {
        let db = try Connection(dbPath)
        
        let wrapper = MealRenameWrapper(mealRename)
        let insert = Tables.mealRename.insert(wrapper.setters)
        try db.run(insert)
        
        let tmpMeal = Meal(id: mealRename.mealId, name: mealRename.name)
        let searchWrapper = SearchableMealWrapper(tmpMeal, nil)
        let searchInsert = Tables.searchableMeal.insert(searchWrapper.setters)
        try db.run(searchInsert)
    }
    
    public func deleteMeal(_ mealDelete: MealDelete) throws {
        let wrapper = MealDeleteWrapper(mealDelete)
        let insert = Tables.mealDelete.insert(wrapper.setters)
        try Connection(dbPath).run(insert)
    }
    
    public func deleteFood(_ foodDelete: FoodDelete) throws {
        let wrapper = FoodDeleteWrapper(foodDelete)
        let insert = Tables.foodDelete.insert(wrapper.setters)
        try Connection(dbPath).run(insert)
    }
}

fileprivate enum Tables {
    public static var meal = Table("Meal")
    public static var foodWithPortion = Table("FoodWithPortion")
    public static var mealRename = Table("MealRename")
    public static var mealDelete = Table("MealDelete")
    public static var foodDelete = Table("FoodDelete")
    public static var searchableMeal = VirtualTable("SearchableMeal")
}

fileprivate enum Columns {
    public static var id = Expression<Int>("Id")
    public static var created = Expression<DatabaseDate>("Created")
    public static var name = Expression<String>("Name")
    public static var mealName = Expression<String>("Name")
    public static var mealId = Expression<Int>("MealId")
    public static var foodFdcId = Expression<Int>("FoodFdcId")
    public static var foodName = Expression<String>("FoodName")
    public static var portionAmount = Expression<Double>("PortionAmount")
    public static var portionGramWeight = Expression<Double>("PortionGramWeight")
    public static var portionName = Expression<String>("PortionName")
    public static var foodId = Expression<Int>("FoodId")
    public static var rank = Expression<Double>("rank")
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

fileprivate class MealWrapper: DatabaseEntityWrapper<Meal> {
    var meal: Meal {
        get { entity }
    }
    
    init(_ row: Row) {
        let name = row[Columns.name]
        super.init(row, Meal(name: name))
    }
    
    override init(_ meal: Meal) {
        super.init(meal)
    }
    
    override var setters: [Setter] {
        get { super.setters + [ Columns.name <- meal.name ] }
    }
}

fileprivate class FoodDeleteWrapper: DatabaseEntityWrapper<FoodDelete> {
    var foodDelete: FoodDelete {
        get { entity }
    }
    
    init(_ row: Row) {
        let foodId = row[Columns.foodId]
        super.init(row, FoodDelete(foodId))
    }
    
    override init(_ foodDelete: FoodDelete) {
        super.init(foodDelete)
    }
    
    override var setters: [Setter] {
        get { super.setters + [ Columns.foodId <- foodDelete.foodId ] }
    }
}

fileprivate class MealDeleteWrapper: DatabaseEntityWrapper<MealDelete> {
    var mealDelete: MealDelete {
        get { entity }
    }
    
    init(_ row: Row) {
        let mealId = row[Columns.mealId]
        super.init(row, MealDelete(mealId))
    }
    
    override init(_ mealDelete: MealDelete) {
        super.init(mealDelete)
    }
    
    override var setters: [Setter] {
        get { super.setters + [ Columns.mealId <- mealDelete.mealId ] }
    }
}

fileprivate class MealRenameWrapper: DatabaseEntityWrapper<MealRename> {
    var mealRename: MealRename {
        get { entity }
    }
    
    init(_ row: Row) {
        let mealId = row[Columns.mealId]
        let name = row[Columns.name]
        super.init(row, MealRename(mealId: mealId, name: name))
    }
    
    override init(_ mealRename: MealRename) {
        super.init(mealRename)
    }
    
    override var setters: [Setter] {
        get { super.setters + [ Columns.mealId <- mealRename.mealId, Columns.name <- mealRename.name ] }
    }
}

fileprivate class FoodWithPortionWrapper: DatabaseEntityWrapper<Meal.FoodWithPortion> {
    var foodWithPortion: Meal.FoodWithPortion {
        get { entity }
    }
    
    static func from(_ rows: AnySequence<Row>) -> [Meal.FoodWithPortion] {
        var foods = [Meal.FoodWithPortion]()
        for row in rows {
            let wrapped = FoodWithPortionWrapper(row)
            foods.append(wrapped.foodWithPortion)
        }
        return foods
    }
    
    init(_ row: Row) {
        super.init(row, Meal.FoodWithPortion(
            mealId: row[Columns.mealId],
            foodFdcId: row[Columns.foodFdcId],
            foodName: row[Columns.foodName],
            portionAmount: row[Columns.portionAmount],
            portionGramWeight: row[Columns.portionGramWeight],
            portionName: row[Columns.portionName]
        ))
    }
    
    override init(_ foodWithPortion: Meal.FoodWithPortion) {
        super.init(foodWithPortion)
    }
    
    override var setters: [Setter] {
        super.setters + [
            Columns.mealId <- foodWithPortion.mealId,
            Columns.foodFdcId <- foodWithPortion.foodFdcId,
            Columns.foodName <- foodWithPortion.foodName,
            Columns.portionAmount <- foodWithPortion.portionAmount,
            Columns.portionGramWeight <- foodWithPortion.portionGramWeight,
            Columns.portionName <- foodWithPortion.portionName,
        ]
    }
}

fileprivate class SearchableMealWrapper {
    var searchableMeal: UserMealsSearchableMeal

    init(_ row: Row) {
        self.searchableMeal = UserMealsSearchableMeal(
            mealId: row[Columns.mealId],
            foodId: row[Columns.foodId],
            mealName: row[Columns.mealName],
            foodName: row[Columns.foodName],
            rank: row[Columns.rank]
        )
    }
    
    init(_ entity: UserMealsSearchableMeal) {
        self.searchableMeal = entity
    }
    
    init(_ meal: Meal, _ food: Meal.FoodWithPortion?) {
        self.searchableMeal = UserMealsSearchableMeal(
            mealId: meal.id,
            foodId: food?.id ?? -1,
            mealName: meal.name,
            foodName: food?.foodName ?? "",
            rank: 0
        )
    }
    
    open var setters: [Setter] {
        get { [
            Columns.mealId <- searchableMeal.mealId,
            Columns.foodId <- searchableMeal.foodId,
            Columns.mealName <- searchableMeal.mealName,
            Columns.foodName <- searchableMeal.foodName
        ] }
    }
}
