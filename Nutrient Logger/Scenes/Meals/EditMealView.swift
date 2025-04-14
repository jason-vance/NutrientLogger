//
//  EditMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration

struct EditMealView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Inject var mealsDatabase: UserMealsDatabase
    @Inject var analytics: UserMealsAnalytics
    
    let meal: Meal?
    
    @State private var isLoading: Bool = true
    
    var body: some View {
        List {
            //TODO: MVP: Name Field
            //TODO: MVP: Food List
            //TODO: MVP: Some Nutrition Facts?
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .overlay(alignment: .bottomTrailing) {
            AddFoodButton()
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(meal?.name ?? "New Meal")
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
    
    @ViewBuilder private func AddFoodButton() -> some View {
        NavigationFab(systemName: "plus") {
            //TODO: MVP: Navigate to FoodSearchView() { foods.append($0) }
            Text("FoodSearchView() { foods.append($0) }")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserMealsDatabase.self) {UserMealsDatabaseForScreenshots()}
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}
    
    NavigationStack {
        EditMealView(meal: nil)
    }
}
