//
//  EditMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Save meal button
//TODO: MVP: Discard confirmation dialog
struct EditMealView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Inject var mealsDatabase: UserMealsDatabase
    @Inject var analytics: UserMealsAnalytics
    
    @State var meal: Meal?
    
    @State private var isLoading: Bool = true
    
    private var mealNameBinding: Binding<String> {
        .init(
            get: { meal?.name ?? "" },
            set: {
                if let _ = meal {
                    self.meal?.name = $0
                } else {
                    meal = Meal(name: $0)
                }
            }
        )
    }
    
    var body: some View {
        List {
            NameField()
            //TODO: MVP: Food List
            //TODO: MVP: Some Nutrition Facts?
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .overlay(alignment: .bottomTrailing) {
            AddFoodButton()
        }
        .scrollDismissesKeyboard(.immediately)
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
    
    @ViewBuilder private func NameField() -> some View {
        Section(header: Text("Meal Name")) {
            TextField(
                "Meal Name",
                text: mealNameBinding,
                axis: .vertical,
            )
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserMealsDatabase.self) {UserMealsDatabaseForScreenshots()}
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}
    
    NavigationStack {
        EditMealView(meal: nil)
    }
}
