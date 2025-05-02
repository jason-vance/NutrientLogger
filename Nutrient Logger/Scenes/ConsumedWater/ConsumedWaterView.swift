//
//  ConsumedWaterView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import SwiftUI

//TODO: Add a quick add button
//TODO: Convert food water amounts from grams to cups
//TODO: Add water goal setting
//TODO: Add ads
struct ConsumedWaterView: View {
    
    private struct MealFoods: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let foods: [FoodItem]
    }
    
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService

    let date: SimpleDate
    let aggregator: NutrientDataAggregator
    
    private var waterGoalCups: Double? {
        if let waterGoalGrams = rdiLibrary
            .getRdis(FdcNutrientGroupMapper.NutrientNumber_Water)?
            .getRdi(userService.currentUser) {
            return waterGoalGrams.recommendedAmount / 237
        }
        return 0
    }
    
    private var waterMealFoods: [MealFoods] {
        var mealTimeFoodMap: [MealTime: [FoodItem]] = [:]
        
        aggregator.foods
            .forEach { food in
                mealTimeFoodMap[food.mealTime ?? .none, default: []].append(food)
            }
        
        return mealTimeFoodMap
            .reduce(into: []) { result, element in
                result.append(MealFoods(mealTime: element.key, foods: element.value))
            }
            .sorted { $0.mealTime < $1.mealTime }
    }
    
    var body: some View {
        List {
            TotalWaterCard()
            FoodsContainingWater()
        }
        .listDefaultModifiers()
        .navigationTitle("\(date.formatted())'s Water")
    }
    
    @ViewBuilder private func TotalWaterCard() -> some View {
        let lineWidth: CGFloat = 32
        
        HStack {
            Spacer()
            GeometryReader { geometry in
                ZStack {
                    let waterCupsMax: CGFloat = waterGoalCups ?? 10
                    let waterCups = aggregator.waterCups
                    let waterProgress: CGFloat = waterCups / waterCupsMax

                    Circle()
                        .stroke(style: .init(
                            lineWidth: lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: 0, to: waterProgress)
                        .stroke(style: .init(
                            lineWidth: lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(Color.blue)
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text("Total Water")
                            .font(.headline)
                            .fontWeight(.light)
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(Color.blue)
                            Text("\(waterCups.formatted(maxDigits: 1)) cups")
                                .contentTransition(.numericText())
                        }
                        .font(.title)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    }
                    .offset(y: -5)
                }
            }
            .frame(width: 250, height: 250)
            Spacer()
        }
        .padding(lineWidth / 2)
        .foregroundStyle(Color.text)
        .padding()
        .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FoodsContainingWater() -> some View {
        if !waterMealFoods.isEmpty {
            Section {
                ForEach(waterMealFoods) { waterMealFood in
                    Text(waterMealFood.mealTime.rawValue)
                        .listSubsectionHeader()
                    ForEach(waterMealFood.foods.indices) { foodIndex in
                        ConsumedNutrientDetailsFoodRow(
                            nutrientNumber: FdcNutrientGroupMapper.NutrientNumber_Water,
                            food: waterMealFood.foods[foodIndex]
                        )
                    }
                }
            } header: {
                Text("Contributing Foods")
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {UsdaNutrientRdiLibrary.create()}
    let _ = swinjectContainer.autoregister(UserService.self) {UserServiceForScreenshots()}

    let foods = FoodItem.sampleFoods
    let aggregator = NutrientDataAggregator(foods)
        
    NavigationStack {
        ConsumedWaterView(
            date: .today,
            aggregator: aggregator
        )
    }
}
