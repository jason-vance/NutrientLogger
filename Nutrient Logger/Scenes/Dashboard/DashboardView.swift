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
    
    @State private var date: Date = .now
    @State private var foods: [FoodItem] = [.dashboardSample]
    
    private let localDatabase: LocalDatabase = swinjectContainer~>LocalDatabase.self
    
    private func fetchFoods() {
        foods = []
        
        Task {
            do {
                foods = try localDatabase.getFoodsOrderedByDateLogged(date)
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
    
    var body: some View {
        List {
            WhatIAteSection()
        }
        .listDefaultModifiers()
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .onChange(of: date, initial: true) { fetchFoods() }
        .animation(.snappy, value: foods)
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Date Control")
        }
    }
    
    @ViewBuilder private func WhatIAteSection() -> some View {
        if !foods.isEmpty {
            let meals = DashboardMealList.from(foods)
            
            Section {
                ForEach(meals) { meal in
                    Text(meal.name)
                        .font(.footnote.bold())
                        .listRowDefaultModifiers()
                    ForEach(foods) { food in
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
    
    NavigationStack {
        DashboardView()
    }
}
