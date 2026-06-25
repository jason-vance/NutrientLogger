//
//  DataController.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 1/16/26.
//

import SwiftData
import Foundation
import CoreData
import Combine

@MainActor
class DataController: ObservableObject {
    
    static let shared = DataController()
    
    let container: ModelContainer
    
    @Inject private var remoteDatabase: RemoteDatabase
    private var cancellables = Set<AnyCancellable>()
    var onNutrientsUpdated: (([String: Double], Date) -> Void)?
    
    init() {
        do {
            let fileManager = FileManager.default
            
            // The OLD location (Default App Sandbox)
            let oldStoreURL = fileManager
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("default.store")
            
            // The NEW location (App Group Shared Container)
            let groupURL = fileManager
                .containerURL(forSecurityApplicationGroupIdentifier: "group.com.jasonsapps.NutrientLogger")?
                .appendingPathComponent("default.store")
            
            guard let oldStoreURL, let groupURL else {
                throw NSError(domain: "DataController", code: 0, userInfo: nil)
            }
            
            let oldStoreExists = fileManager.fileExists(atPath: oldStoreURL.path)
            let groupStoreExists = fileManager.fileExists(atPath: groupURL.path)
            if oldStoreExists && !groupStoreExists {
                print("Migration: Old store found. Moving to App Group...")
                do {
                    try Self.migrateStore(from: oldStoreURL, to: groupURL)
                } catch {
                    print("Migration Failed: \(error)")
                }
            }
            
            let schema = Schema([
                ConsumedFood.self,
                RecentSearch.self,
                Meal.self,
                DailySummary.self,
                WeightEntry.self,
                BodyFatEntry.self
            ])
            let config = ModelConfiguration(schema: schema, url: groupURL)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to configure SwiftData container: \(error)")
        }
    }
    
    func updateDailySummary() {
        let today = SimpleDate.today
        let descriptor = FetchDescriptor<ConsumedFood>(
            predicate: #Predicate { $0.dateLogged == today }
        )
        let consumedFoods = (try? container.mainContext.fetch(descriptor)) ?? []
        
        let foodItems = consumedFoods
            .compactMap { consumedFood in
                do {
                    var food = try remoteDatabase.getFood(String(consumedFood.fdcId))
                    food = try food?.applyingPortion(consumedFood.portion)
                    food?.dateLogged = consumedFood.dateLogged
                    food?.mealTime = consumedFood.mealTime
                    return food
                } catch {
                    print("Failed to fetch food with id \(consumedFood.fdcId): \(error)")
                }
                return nil
            }
        
        let aggregator = NutrientDataAggregator(foodItems)
        let waterGrams = aggregator.waterCups * 237
        let summary = DailySummary(
            date: .now,
            calories: aggregator.calories,
            protein: aggregator.protein,
            carbs: aggregator.carbs,
            fat: aggregator.fat,
            waterGrams: waterGrams
        )
        container.mainContext.insert(summary)
        try? container.mainContext.save()

        var nutrientTotals: [String: Double] = [:]
        for (fdcNumber, pairs) in aggregator.nutrientsByNutrientNumber {
            if let combined = NutrientDataAggregator.combineNutrients(pairs.map(\.nutrient)) {
                nutrientTotals[fdcNumber] = combined.amount
            }
        }
        onNutrientsUpdated?(nutrientTotals, .now)
    }
        
    
    /// Helper to move the main DB file plus the write-ahead logs (.wal / .shm)
    private static func migrateStore(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Helper to move a single file if it exists
        func moveFile(extension: String) throws {
            let source = URL(string: sourceURL.absoluteString + "-\(`extension`)")!
            let dest = URL(string: destinationURL.absoluteString + "-\(`extension`)")!
            
            // The .store file has no extra extension, handle that case
            let realSource = `extension`.isEmpty ? sourceURL : source
            let realDest = `extension`.isEmpty ? destinationURL : dest

            if fileManager.fileExists(atPath: realSource.path) {
                try fileManager.moveItem(at: realSource, to: realDest)
                print("Moved: \(realSource.lastPathComponent)")
            } else {
                print("Didn't Move: \(source.lastPathComponent) - it didn't exist")
            }
        }

        // Move the 3 key files
        try moveFile(extension: "")      // The main .store file
        try moveFile(extension: "wal")   // Write-Ahead Log
        try moveFile(extension: "shm")   // Shared Memory file
    }
}
