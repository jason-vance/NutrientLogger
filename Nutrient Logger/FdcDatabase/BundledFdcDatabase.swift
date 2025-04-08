//
//  BundledFdcDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

class BundledFdcDatabase: RemoteDatabase {
    private static let portion_QuantityNotSpecified = "Quantity not specified"
    private static let portion_DefaultAmount: Double = 1
    
    private static let supportingDataDbName = "fdc_supporting_data.db"
    private static let legacyDbName = "fdc_legacy.db"
    private static let surveyDbName = "fdc_survey.db"

    private static var dbDir: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask)
            .first!
    }

    private let legacyData: FdcSearchableFoodDatabase!
    private let surveyData: FdcSearchableFoodDatabase!
    private let supportingData: FdcSupportingDataDatabase!

    public init() async throws {
        try await BundledFdcDatabase.transferDbFileIfNecessary(BundledFdcDatabase.legacyDbName)
        try await BundledFdcDatabase.transferDbFileIfNecessary(BundledFdcDatabase.surveyDbName)
        try await BundledFdcDatabase.transferDbFileIfNecessary(BundledFdcDatabase.supportingDataDbName)

        let dir = BundledFdcDatabase.dbDir
        legacyData = try await FdcSearchableFoodDatabase(dbPath: dir.appendingPathComponent(BundledFdcDatabase.legacyDbName))
        surveyData = try await FdcSearchableFoodDatabase(dbPath: dir.appendingPathComponent(BundledFdcDatabase.surveyDbName))
        supportingData = try FdcSupportingDataDatabase(dbPath: dir.appendingPathComponent(BundledFdcDatabase.supportingDataDbName))
    }

    private static func transferDbFileIfNecessary(_ dbName: String) async throws {
        _ = try await Task.init(priority: .userInitiated) {
            let toURL = BundledFdcDatabase.dbDir.appendingPathComponent(dbName)
            if (FileManager().fileExists(atPath: toURL.path)) {
                return
            }
            
            let fromURL = Bundle.main.url(forResource: dbName, withExtension: nil)
            try FileManager().copyItem(at: fromURL!, to: toURL)
        }.value
    }

    public func getFood(_ foodId: String) throws -> FoodItem? {
        guard let foodIdInt = Int(foodId)
        else {
            return nil
        }
        
        if let legacyFood = try legacyData.getFood(foodIdInt) {
            return try makeFoodItem(legacyFood)
        }

        if let surveyFood = try surveyData.getFood(foodIdInt) {
            return try makeFoodItem(surveyFood)
        }

        return nil
    }

    private func makeFoodItem(_ food: FdcFood) throws -> FoodItem {
        let nutrientLinks = try getNutrientLinks(food.fdcId)
        let nutrients = try supportingData.getNutrients(nutrientLinks)

        let group = FdcNutrientGroupMapper.makeGroupNutrient(FdcNutrientGroupMapper.GroupNumber_Other)
        group.nutrients = nutrientsFrom(nutrients)

        var groups = [NutrientGroup]()
        groups.append(group)

        return FoodItem(
            fdcId: food.fdcId,
            name: food.description,
            fdcType: food.dataType,
            nutrientGroups: groups,
            gramWeight: 100
        )
    }

    private func nutrientsFrom(_ nutrients: [FdcNutrientLink:FdcNutrient]) -> [Nutrient] {
        var rv = [Nutrient]()

        for (link, nutrient) in nutrients {
            if (link.amount == 0) {
                continue
            }

            rv.append(FdcNutrientGroupMapper.makeNutrient(nutrient, link.amount))
        }

        return rv
    }

    private func getNutrientLinks(_ foodId: Int) throws -> [FdcNutrientLink] {
        let legacyLinks = try legacyData.getNutrientLinks(foodId)
        if (!legacyLinks.isEmpty) {
            return legacyLinks
        }

        let surveyLinks = try surveyData.getNutrientLinks(foodId)
        if (!surveyLinks.isEmpty) {
            return surveyLinks
        }

        return []
    }

    public func getPortions(_ food: FoodItem) throws -> [Portion] {
        let legacyPortions = try legacyData.getPortions(food.fdcId)
        if (!legacyPortions.isEmpty) {
            return BundledFdcDatabase.makePortions(legacyPortions)
        }

        let surveyPortions = try surveyData.getPortions(food.fdcId)
        if (!surveyPortions.isEmpty) {
            return BundledFdcDatabase.makePortions(surveyPortions)
        }

        return BundledFdcDatabase.makePortions()
    }

    private static func makePortions(_ portions: [FdcPortion] = []) -> [Portion] {
        var rv = [Portion]()
        
        for portion in portions {
            if (portion_QuantityNotSpecified == portion.description) {
                continue
            }

            rv.append(portionFrom(portion))
        }

        rv.append(Portion.defaultPortion)
        return rv
    }

    public static func portionFrom(_ portion: FdcPortion) -> Portion {
        let amountStr = portion.description?.split(separator: " ").first
        let parsedAmount = amountStr != nil ? Double(amountStr!) : nil
        let amount = parsedAmount ?? portion.amount ?? portion_DefaultAmount

        let portionDesc = portion.description
        var description = (portionDesc == nil || portionDesc!.isEmpty) ? portion.modifier! : portionDesc!
        if (parsedAmount != nil) {
            description = String(description.dropFirst(amountStr!.count + 1))
        }

        let gramWeight = portion.gramWeight / amount
        
        return Portion(
            name: description,
            amount: amount,
            gramWeight: gramWeight
        )
    }

    public func search(_ query: String) throws -> SearchResult {
        let ftsQuery = FtsQueryGenerator.generateFrom(query)

        var foods = [FdcSearchableFood]()
        foods.append(contentsOf: try legacyData.search(ftsQuery))
        foods.append(contentsOf: try surveyData.search(ftsQuery))
        foods = foods.sorted { $0.rank < $1.rank }

        return SearchResult(foods.map {
            SearchResultItem(obj: $0.fdcId, name: $0.description, category: .remoteDatabaseFoods)
        })
    }

    public func getAllNutrientsLinkedToFoods() throws -> [Nutrient] {
        let legacyCounts = try legacyData.countFoodsContainingNutrients()
        let surveyCounts = try surveyData.countFoodsContainingNutrients()

        let nutrients = try supportingData.getAllNutrients()
        
        return nutrients
            .filter { nutrient in
                (legacyCounts.keys.contains(nutrient.id) && legacyCounts[nutrient.id]!.count > 0)
                || (surveyCounts.keys.contains(nutrient.id) && surveyCounts[nutrient.id]!.count > 0)
            }
            .map { FdcNutrientGroupMapper.makeNutrient($0) }
    }

    public func getAllNutrients() throws -> [Nutrient] {
        let nutrients = try supportingData.getAllNutrients()
        return nutrients.map { FdcNutrientGroupMapper.makeNutrient($0) }
    }

    public func getFoodsContainingNutrient(_ nutrient: Nutrient) throws -> [NutrientFoodPair] {
        var pairs = [FdcNutrientFoodPair]()
        pairs.append(contentsOf: try surveyData.getFoodsContainingNutrient(nutrient))
        pairs.append(contentsOf: try legacyData.getFoodsContainingNutrient(nutrient))

        let nut = try supportingData.getNutrient(nutrient.fdcNumber)
        
        return pairs.sorted {
            $0.nutrientLink.amount > $1.nutrientLink.amount
        }.map { pair in
            let rvNut = FdcNutrientGroupMapper.makeNutrient(nut!, pair.nutrientLink.amount)
            let rvFood = FoodItem(
                fdcId: pair.food.fdcId,
                name: pair.food.description,
                fdcType: pair.food.dataType,
                gramWeight: 100,
                portionName: "Grams",
                amount: 100
            )
            return NutrientFoodPair(nutrient: rvNut, food: rvFood)
        }
    }
}
