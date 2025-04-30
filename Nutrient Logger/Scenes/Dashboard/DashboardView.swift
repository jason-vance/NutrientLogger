//
//  DashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

//TODO: RELEASE: Navigate to carbs from carbs cell
//TODO: RELEASE: Navigate to lipids from fat cell
//TODO: RELEASE: Navigate to amino acids from protein cell
//TODO: RELEASE: Navigate to WaterDetailView from water cell
//TODO: RELEASE: Navigate to CaloriesDetailView from calories cell (Maybe this is where consumed foods are found)
//TODO: Days with foods hang for a second while loading
//TODO: RELEASE: Foods with long names are not left aligned on dashboard
struct DashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var date: SimpleDate = .today
    @Query private var consumedFoods: [ConsumedFood]
    
    private var todaysConsumedFoods: [ConsumedFood] {
//        return FoodItem.sampleFoods
//            .map {
//                ConsumedFood(
//                    fdcId: $0.fdcId,
//                    name: $0.name,
//                    portionAmount: $0.amount,
//                    portionGramWeight: $0.gramWeight,
//                    portionName: $0.portionName,
//                    dateLogged: .today,
//                    mealTime: $0.mealTime!
//                )
//            }
        
        consumedFoods
            .filter { $0.dateLogged == date }
            .sorted { $0.name < $1.name }
    }
    
    @State private var foodItems: [FoodItem] = []
    @State private var aggregator: NutrientDataAggregator?

    private func fetchFoods() {
//        foodItems = FoodItem.sampleFoods
//        return;
        
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
            aggregator = NutrientDataAggregator(foodItems)
        }
    }
    
    var navigationTitle: String {
        let date = Date.now
        
        let hour = Calendar.current.component(.hour, from: date)
        
        if hour >= 0 && hour < 2 {
            return "Try Sleep?"
        } else if hour >= 2 && hour < 12 {
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
        ScrollView {
            VStack {
                NativeAdListRow(ad: $ad, size: .medium)
                    .padding(.horizontal)
                if todaysConsumedFoods.isEmpty {
                    LoggingInstructions()
                } else {
                    MyNutrientsSection()
                    WhatIAteSection()
                }
            }
        }
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .onChange(of: todaysConsumedFoods, initial: true) { fetchFoods() }
        .animation(.snappy, value: date)
        .animation(.snappy, value: todaysConsumedFoods)
        .animation(.snappy, value: foodItems)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
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
    
    @ViewBuilder private func LoggingInstructions() -> some View {
        ContentUnavailableView(
            "Feeling Hungry?",
            systemImage: "face.smiling.inverse",
            description: Text("You haven't logged anything yet today. Go to the search tab to find foods and add them to your log!")
        )
        .listRowDefaultModifiers()
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
            
            VStack {
                HStack {
                    Text("What I Ate Today")
                        .listSectionHeader()
                    Spacer()
                }
                .padding(.top)
                LazyVStack {
                    ForEach(meals) { meal in
                        HStack {
                            Text(meal.name)
                                .listSubsectionHeader()
                            Spacer()
                        }
                        .padding(.top, 4)
                        ForEach(meal.foods) { food in
                            DashboardFoodRow(food: food)
                        }
                    }
                }
            }
            .padding(.horizontal)
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
    .environmentObject(AdProviderFactory.forDev)
}
