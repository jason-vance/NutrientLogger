//
//  DashboardMealRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

//TODO: RELEASE: Apply portions to foodItems
struct DashboardMealRow: View {
    
    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal
    static let carbsKey = FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference
    static let fatKey = FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat
    static let proteinKey = FdcNutrientGroupMapper.NutrientNumber_Protein
    
    @State var meal: DashboardMealList.Meal
    @State var date: SimpleDate
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var foodItems: [(FoodItem, ConsumedFood)] = []
    @State private var aggregator: NutrientDataAggregator?
    @State private var caloriesString: String = ""
    @State private var foodCountString: String = ""
    @State private var weightString: String = ""
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var protein: Double = 0
    @State private var totalMacroCals: Double = 0

    private func fetchFoods() async {
        guard foodItems.isEmpty else { return }
//        foodItems = FoodItem.sampleFoods
//        return;
        
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
            aggregator = NutrientDataAggregator(foodItems.map { $0.0 })
            
            let calsAmount = aggregator!.nutrientsByNutrientNumber[Self.calsKey]?
                .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
            caloriesString = "\(calsAmount.formatted(maxDigits: 0)) cals"
            
            foodCountString = {
                if meal.foods.count == 1 {
                    return "1 food"
                } else {
                    return "\(meal.foods.count) foods"
                }
            }()
            
            let weight = meal.foods
                .reduce(into: 0.0, { $0 += $1.portionAmount * $1.portionGramWeight })
            weightString = "\(weight.formatted(maxDigits: 0))g"
            
            carbs = aggregator?
                .nutrientsByNutrientNumber[Self.carbsKey]?
                .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
            fat = aggregator?
                .nutrientsByNutrientNumber[Self.fatKey]?
                .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
            protein = aggregator?
                .nutrientsByNutrientNumber[Self.proteinKey]?
                .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
            totalMacroCals = (carbs * 4) + (fat * 9) + (protein * 4)
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
            Text(foodItems.isEmpty ? "xxxxxx" : text)
                .contentTransition(.numericText())
                .redacted(reason: foodItems.isEmpty ? [.placeholder] : [])
        }
        .font(.footnote)
    }
    
    @ViewBuilder private func CarbsFatProtein() -> some View {
        HStack {
            Macro(
                name: "Carbs",
                amount: carbs,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: foodItems.isEmpty ? .gray : .indigo
            )
            Macro(
                name: "Fat",
                amount: fat,
                calorieFactor: 9,
                totalMacroCals: totalMacroCals,
                color: foodItems.isEmpty ? .gray : .red
            )
            Macro(
                name: "Protein",
                amount: protein,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: foodItems.isEmpty ? .gray : .green
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
                        .redacted(reason: foodItems.isEmpty ? [.placeholder] : [])
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
