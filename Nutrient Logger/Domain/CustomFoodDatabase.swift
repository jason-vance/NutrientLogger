//
//  CustomFoodDatabase.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/16/26.
//

import Foundation
import Combine

@MainActor
class CustomFoodDatabase: ObservableObject {

    static let shared = CustomFoodDatabase()

    // Only non-archived foods. Drives UI (search lists, etc.).
    @Published private(set) var foods: [CustomFood] = []

    // All foods including archived. Used for ConsumedFood lookups so deleted
    // foods still display their nutrient data in ConsumedMealsView.
    private var _allFoods: [CustomFood] = []

    // Synchronous read cache for nonisolated callers (CompositeRemoteDatabase).
    // Written only on main actor; nonisolated(unsafe) suppresses actor-isolation checks.
    private nonisolated(unsafe) var _cache: [Int: CustomFood] = [:]

    private let fileURL: URL

    init() {
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.jasonsapps.NutrientLogger")

        fileURL = (groupURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!)
            .appendingPathComponent("custom_foods.json")

        load()
    }

    // MARK: - Nonisolated read path (safe for CompositeRemoteDatabase)

    nonisolated func getFoodItem(withId id: Int) -> FoodItem? {
        _cache[id]?.toFoodItem()
    }

    nonisolated func getPortions(forId id: Int) -> [Portion] {
        guard let food = _cache[id] else { return [.defaultPortion] }
        return [food.toPortion(), .defaultPortion]
    }

    nonisolated func getFood(withId id: Int) -> CustomFood? {
        _cache[id]
    }

    // MARK: - Main-actor queries

    func nextId() -> Int {
        let minId = _allFoods.map { $0.customFoodId }.min() ?? 0
        return min(minId - 1, -1)
    }

    // MARK: - Mutations (main actor)

    func save(_ food: CustomFood) {
        if let idx = _allFoods.firstIndex(where: { $0.customFoodId == food.customFoodId }) {
            _allFoods[idx] = food
        } else {
            _allFoods.append(food)
        }
        _cache[food.customFoodId] = food
        foods = _allFoods.filter { !$0.isArchived }
        persist()
    }

    // Soft-delete: the food is archived so ConsumedFood entries can still resolve it.
    func delete(_ food: CustomFood) {
        if let idx = _allFoods.firstIndex(where: { $0.customFoodId == food.customFoodId }) {
            _allFoods[idx].isArchived = true
            _cache[food.customFoodId] = _allFoods[idx]
        }
        foods = _allFoods.filter { !$0.isArchived }
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([CustomFood].self, from: data)
        else { return }
        _allFoods = decoded
        foods = _allFoods.filter { !$0.isArchived }
        _cache = Dictionary(uniqueKeysWithValues: _allFoods.map { ($0.customFoodId, $0) })
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(_allFoods) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
