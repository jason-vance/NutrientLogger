//
//  ContentView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var isSetup: Bool = false
    
    var body: some View {
        AppSetupRouter()
            .animation(.snappy, value: isSetup)
    }
    
    @ViewBuilder private func AppSetupRouter() -> some View {
        ZStack {
            if isSetup {
                MainContent()
            } else {
                AppSetupView(isSetup: $isSetup)
            }
        }
    }
    
    @ViewBuilder private func MainContent() -> some View {
        TabView {
            Tab("Dashboard", systemImage: "gauge.with.dots.needle.33percent") {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    FoodSearchView(onFoodSaved: FoodSaver.forConsumedFoods.saveFoodItem)
                }
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack {
                    UserProfileView()
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
