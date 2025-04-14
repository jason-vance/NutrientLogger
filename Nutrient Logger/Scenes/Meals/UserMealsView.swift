//
//  UserMealsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserMealsView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    private let mealsDatabase = swinjectContainer~>UserMealsDatabase.self
    private let analytics = swinjectContainer~>UserMealsAnalytics.self
    
    @State private var isLoading: Bool = true
    @State private var meals: [Meal]? = nil
    
    private func fetchMeals() {
        isLoading = true
        Task {
            do {
                meals = try mealsDatabase.getMeals()
            } catch {
                print("Failed to fetch meals: \(error)")
            }
            isLoading = false
        }
    }

    var body: some View {
        List {
            if let meals = meals {
                if meals.isEmpty {
                    ContentUnavailableView("No Meals... Yet!", systemImage: "fryingpan")
                } else {
                    ForEach(meals) { meal in
                        MealRow(meal)
                    }
                }
            }
            SpaceForFab()
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .onAppear { fetchMeals() }
        .overlay(alignment: .bottomTrailing) {
            AddMealButton()
        }
        .overlay {
            if isLoading {
                ZStack {
                    Rectangle()
                        .fill(.regularMaterial)
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("My Meals")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func MealRow(_ meal: Meal) -> some View {
        NavigationLink {
            //TODO: Navigate to EditMealView()
            Text("EditMealView: \(meal.name)")
        } label: {
            Text(meal.name)
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func SpaceForFab() -> some View {
        Spacer(minLength: 100)
            .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func AddMealButton() -> some View {
        NavigationFab(systemName: "plus") {
            //TODO: Navigaite to EditMealView()
            Text("EditMealView: new meal")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserMealsDatabase.self) {UserMealsDatabaseForScreenshots()}
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}

    NavigationStack {
        UserMealsView()
    }
}
