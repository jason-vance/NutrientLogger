//
//  DashboardMealRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

//TODO: RELEASE: Speed up the rendering here
struct DashboardMealRow: View {
    
    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal
    static let carbsKey = FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference
    static let fatKey = FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat
    static let proteinKey = FdcNutrientGroupMapper.NutrientNumber_Protein
    
    let meal: DashboardMealList.Meal
    let date: SimpleDate
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var foodItems: [(FoodItem, ConsumedFood)] = []
    @State private var aggregator: NutrientDataAggregator?
    
    private var caloriesString: String {
        guard let aggregator else { return "" }
        
        let calsAmount = aggregator.nutrientsByNutrientNumber[Self.calsKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        return "\(calsAmount.formatted(maxDigits: 0)) cals"
    }
    
    private var foodCountString: String {
        if meal.foods.count == 1 {
            return "1 food"
        } else {
            return "\(meal.foods.count) foods"
        }
    }
    
    private var weightString: String {
        let weight = meal.foods
            .reduce(into: 0.0, { $0 += $1.portionAmount * $1.portionGramWeight })
        return "\(weight.formatted(maxDigits: 0))g"
    }
    
    private func fetchFoods() async {
        guard foodItems.isEmpty else { return }
//        foodItems = FoodItem.sampleFoods
//        return;
        
        Task {
            let foodItems = meal.foods
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
            
            self.foodItems = foodItems
            self.aggregator = aggregator
        }
    }
    
    var body: some View {
        NavigationLink {
            ConsumedMealsView(date: date)
        } label: {
            VStack {
                HStack {
                    Text(meal.name)
                        .font(.headline)
                    Spacer()
                }
                CaloriesWeightFoods()
                CarbsFatProtein()
                    .padding(.top, 8)
            }
            .foregroundStyle(Color.text)
            .padding()
            .inCard(backgroundColor: .gray)
        }
        .task { await fetchFoods() }
    }
    
    @ViewBuilder private func CaloriesWeightFoods() -> some View {
        HStack {
            QuickStat(icon: "flame.fill", iconColor: .orange, text: caloriesString)
            QuickStat(icon: "fork.knife", iconColor: .teal, text: foodCountString)
            QuickStat(icon: "scalemass.fill", iconColor: .purple, text: weightString)
            Spacer()
        }
    }
    
    @ViewBuilder private func QuickStat(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(text)
                .contentTransition(.numericText())
        }
        .font(.footnote)
    }
    
    @ViewBuilder private func CarbsFatProtein() -> some View {
        let carbs = aggregator?
            .nutrientsByNutrientNumber[Self.carbsKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let fat = aggregator?
            .nutrientsByNutrientNumber[Self.fatKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let protein = aggregator?
            .nutrientsByNutrientNumber[Self.proteinKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let totalMacroCals = (carbs * 4) + (fat * 9) + (protein * 4)

        HStack {
            Macro(
                name: "Carbs",
                amount: carbs,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: .indigo
            )
            Macro(
                name: "Fat",
                amount: fat,
                calorieFactor: 9,
                totalMacroCals: totalMacroCals,
                color: .red
            )
            Macro(
                name: "Protein",
                amount: protein,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: .green
            )
        }
    }
    
    @ViewBuilder private func Macro(
        name: String,
        amount: Double,
        calorieFactor: Double,
        totalMacroCals: Double,
        color: Color
    ) -> some View {
        HStack {
            CircleChart(
                amount: amount * calorieFactor,
                total: totalMacroCals,
                config: .init(color: color)
            )
            VStack {
                HStack {
                    Text(name)
                        .font(.footnote)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack {
                    Text("\(amount.formatted(maxDigits:0))g")
                        .contentTransition(.numericText())
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    
    NavigationStack {
        ScrollView {
            VStack {
                DashboardMealRow(meal: .sample, date: .today)
            }
            .padding(.horizontal)
        }
    }
}
