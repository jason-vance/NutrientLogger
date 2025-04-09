//
//  DashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI
import SwinjectAutoregistration

struct DashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var date: SimpleDate = .today
    @State private var foods: [FoodItem] = []
    
    private let localDatabase: LocalDatabase = swinjectContainer~>LocalDatabase.self
    
    private func fetchFoods() {
        Task {
            do {
                let foods = try localDatabase.getFoodsOrderedByDateLogged(date)
                self.foods = foods
            } catch {
                print("Failed to fetch foods: \(error)")
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
    
    private func onChangeDate(old: SimpleDate, new: SimpleDate) {
        guard foods.isEmpty || old != new else {
            return
        }
        
        fetchFoods()
    }
    
    var body: some View {
        List {
            MyNutrientsSection()
            WhatIAteSection()
        }
        .listDefaultModifiers()
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .onChange(of: date, initial: true) { onChangeDate(old: $0, new: $1) }
        .animation(.snappy, value: foods)
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
        if !foods.isEmpty {
            DashboardNutrientSection(foods: foods)
        }
    }
    
    @ViewBuilder private func WhatIAteSection() -> some View {
        if !foods.isEmpty {
            let meals = DashboardMealList.from(foods)
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
    let _ = swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        DashboardView()
    }
}
