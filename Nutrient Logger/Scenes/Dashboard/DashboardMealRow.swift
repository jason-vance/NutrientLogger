//
//  DashboardMealRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

struct DashboardMealRow: View {

    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal

    @State var meal: DashboardMealList.Meal
    @State var date: SimpleDate

    @Inject private var remoteDatabase: RemoteDatabase

    @State private var foodItems: [(FoodItem, ConsumedFood)] = []
    @State private var caloriesString: String = ""

    private func fetchFoods() async {
        guard foodItems.isEmpty else { return }

        Task {
            foodItems = meal.foods
                .compactMap { consumedFood in
                    do {
                        var food = try remoteDatabase.getFood(String(consumedFood.fdcId))
                        food = try food?.applyingPortion(consumedFood.portion)
                        food?.dateLogged = consumedFood.dateLogged
                        food?.mealTime = consumedFood.mealTime
                        if let food {
                            return (food, consumedFood)
                        }
                    } catch {
                        print("Failed to fetch food with id \(consumedFood.fdcId): \(error)")
                    }
                    return nil
                }

            let aggregator = NutrientDataAggregator(foodItems.map { $0.0 })
            let calsAmount = aggregator.nutrientsByNutrientNumber[Self.calsKey]?
                .reduce(into: 0.0) { $0 += $1.nutrient.amount } ?? 0
            caloriesString = "\(calsAmount.formatted(maxDigits: 0)) kcal"
        }
    }

    private var foodNamesString: String {
        meal.foods.map(\.name).joined(separator: ", ")
    }

    var body: some View {
        NavigationLink {
            ConsumedMealsView(date: date)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(foodItems.isEmpty ? "--- kcal" : caloriesString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .redacted(reason: foodItems.isEmpty ? [.placeholder] : [])
                }
                Text(foodNamesString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .task { await fetchFoods() }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }

    NavigationStack {
        ScrollView {
            VStack {
                DashboardMealRow(meal: .sample, date: .today)
            }
            .padding(.horizontal)
            .inCard(backgroundColor: .gray)
        }
    }
}
