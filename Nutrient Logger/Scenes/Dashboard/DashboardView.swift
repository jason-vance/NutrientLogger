//
//  DashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

struct DashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var date: SimpleDate = .today
    @Query private var consumedFoods: [ConsumedFood]
    
    private var todaysConsumedFoods: [ConsumedFood] {
        consumedFoods
            .filter { $0.dateLogged == date }
            .sorted { $0.name < $1.name }
    }
    
    @State private var foodItems: [FoodItem] = []
    
    private func fetchFoods() {
        Task {
            foodItems = todaysConsumedFoods
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
        }
    }
    
    var navigationTitle: String {
        let date = Date.now
        
        let hour = Calendar.current.component(.hour, from: date)
        
        if hour >= 0 && hour < 12 {
            return "Good Morning"
        } else if hour >= 12 && hour < 16 {
            return "Good Afternoon"
        } else if hour >= 16 && hour < 22 {
            return "Good Evening"
        } else {
            return "Up Late?"
        }
    }
    
    var body: some View {
        List {
            MyNutrientsSection()
            WhatIAteSection()
        }
        .listDefaultModifiers()
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .onChange(of: todaysConsumedFoods, initial: true) { fetchFoods() }
        .animation(.snappy, value: date)
        .animation(.snappy, value: todaysConsumedFoods)
        .animation(.snappy, value: foodItems)
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DateButton()
        }
    }
    
    @ViewBuilder private func DateButton() -> some View {
        HStack {
            DecrementDateButton()
            Button {
                
            } label: {
                Text(date.formatted())
            }
            .overlay{
                DatePicker(
                    "",
                    selection: .init(
                        get: { date.toDate() ?? .now },
                        set: { date = SimpleDate(date: $0)! }
                    ),
                    displayedComponents: [.date]
                )
                .blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
            }
            .padding(.horizontal)
            IncrementDateButton()
        }
        .bold()
    }
    
    @ViewBuilder private func DecrementDateButton() -> some View {
        Button {
            date = date.adding(days: -1)
        } label: {
            Image(systemName: "chevron.backward")
        }
    }
    
    @ViewBuilder private func IncrementDateButton() -> some View {
        Button {
            date = date.adding(days: 1)
        } label: {
            Image(systemName: "chevron.forward")
        }
    }

    
    @ViewBuilder private func MyNutrientsSection() -> some View {
        if !foodItems.isEmpty {
            DashboardNutrientSection(foods: foodItems)
        }
    }
    
    @ViewBuilder private func WhatIAteSection() -> some View {
        if !todaysConsumedFoods.isEmpty {
            let meals = DashboardMealList.from(todaysConsumedFoods)
                .sorted { $0.mealTime < $1.mealTime }
            
            Section {
                ForEach(meals) { meal in
                    Text(meal.name)
                        .listSubsectionHeader()
                    ForEach(meal.foods) { food in
                        DashboardFoodRow(food: food)
                    }
                }
            } header: {
                Text("What I Ate Today")
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        DashboardView()
    }
}
