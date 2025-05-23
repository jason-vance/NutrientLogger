//
//  UserMealsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration
import SwiftData

struct UserMealsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var analytics: UserMealsAnalytics

    @State private var isLoading: Bool = true
    @Query private var meals: [Meal]
    
    private var displayMeals: [Meal] {
        meals.sorted { $0.name < $1.name }
    }
    
    private func deleteMeals(at offsets: IndexSet) {
        for offset in offsets {
            let meal = displayMeals[offset]
            if let index = meals.firstIndex(of: meal) {
                let mealToDelete = meals[index]
                modelContext.delete(mealToDelete)
            }
        }
    }
    
    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .medium)
            if meals.isEmpty {
                ContentUnavailableView(
                    "No Meals... Yet!",
                    systemImage: "frying.pan",
                    description: Text("You haven't created any meals yet. Tap the plus (+) button in the bottom right corner to get started!")
                )
                .listRowDefaultModifiers()
            } else {
                ForEach(displayMeals) { meal in
                    MealRow(meal)
                }
                .onDelete { deleteMeals(at: $0) }
            }
            SpaceForFab()
        }
        .listDefaultModifiers()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .animation(.snappy, value: meals)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .overlay(alignment: .bottomTrailing) {
            AddMealButton()
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
            EditMealView(mealToEdit: meal)
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
            EditMealView()
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}

    NavigationStack {
        UserMealsView()
    }
    .environmentObject(AdProviderFactory.forDev)
}
