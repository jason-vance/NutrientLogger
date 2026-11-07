//
//  DashboardMealRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

struct DashboardMealRow: View {

    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal

    let meal: DashboardMealList.Meal
    let date: SimpleDate
    /// Shown under an empty meal: "Repeat yesterday's breakfast". Nil to offer nothing.
    var repeatLabel: String? = nil
    var onRepeat: (() -> Void)? = nil

    @Inject private var remoteDatabase: RemoteDatabase

    @State private var foodItems: [(FoodItem, ConsumedFood)] = []
    @State private var caloriesString: String = ""

    // `meal`'s identity (mealTime) is stable across days, so a plain `.task { }` would only run
    // once and never notice the day or its foods changing underneath it. See `refreshKey`.
    private func fetchFoods() async {
        guard !meal.foods.isEmpty else {
            foodItems = []
            return
        }

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

    /// Changes when the day or the meal's foods change (one added by "Repeat yesterday's", an
    /// amount edited), so the calories are recalculated instead of staying on the placeholder.
    private var refreshKey: String {
        "\(date)|" + meal.foods.map { "\($0.fdcId):\($0.portionAmount):\($0.portionGramWeight)" }.joined(separator: ",")
    }

    private var foodNamesString: String {
        meal.foods.map(\.name).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MealLink()
            if meal.foods.isEmpty, let repeatLabel, let onRepeat {
                Button(action: onRepeat) {
                    Label(repeatLabel, systemImage: "arrow.uturn.backward.circle")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder private func MealLink() -> some View {
        NavigationLink {
            ConsumedMealsView(date: date, scrollToMealTime: meal.mealTime)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if !meal.foods.isEmpty {
                        Text(foodItems.isEmpty ? "--- kcal" : caloriesString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                            .redacted(reason: foodItems.isEmpty ? [.placeholder] : [])
                    }
                }
                Text(meal.foods.isEmpty ? "No foods logged yet" : foodNamesString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .task(id: refreshKey) { await fetchFoods() }
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
