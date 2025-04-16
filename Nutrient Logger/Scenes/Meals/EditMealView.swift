//
//  EditMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Dismiss FoodSearchView when a food is added
//TODO: MVP: Save meal button
//TODO: MVP: Discard confirmation dialog
struct EditMealView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Inject var mealsDatabase: UserMealsDatabase
    @Inject var analytics: UserMealsAnalytics
    
    private let meal: Meal?
    @State var mealName: String = ""
    @State var foodsWithPortions: [Meal.FoodWithPortion] = []
    
    init(mealToEdit meal: Meal) {
        self.meal = meal
    }
    
    init() {
        self.meal = nil
    }
    
    @State private var isLoading: Bool = true
    
    private var hasFoods: Bool {
        !foodsWithPortions.isEmpty
    }
    
    var body: some View {
        List {
            NameField()
            FoodsSection()
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
        .animation(.snappy, value: meal)
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(mealName)
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func AddFoodButton() -> some View {
        NavigationFab(systemName: "plus") {
            FoodSearchView(
                searchFunction: .addFoodToMeal
            ) { food, portion in
                foodsWithPortions.append(.init(food: food, portion: portion))
            }
        }
    }
    
    @ViewBuilder private func NameField() -> some View {
        Section(header: Text("Meal Name")) {
            TextField(
                "Meal Name",
                text: $mealName,
                axis: .vertical,
            )
            .textFieldStyle(.roundedBorder)
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FoodsSection() -> some View {
        Section(header: Text("Foods")) {
            if hasFoods {
                ForEach(foodsWithPortions) { food in
                    FoodRow(food)
                }
                .onDelete {
                    foodsWithPortions.remove(atOffsets: $0)
                }
            } else {
                ContentUnavailableView(
                    "Add Some Foods!",
                    systemImage: "carrot",
                    description: Text("You haven't added any foods to this meal yet. Tap the plus (+) button in the bottom right corner to get started!")
                )
                .listRowDefaultModifiers()
            }
        }
    }
    
    @ViewBuilder private func FoodRow(_ foodWithPortion: Meal.FoodWithPortion) -> some View {
        VStack {
            HStack {
                Text(foodWithPortion.foodName)
                    .bold()
                Spacer()
            }
            HStack {
                Text("\(foodWithPortion.portionAmount.formatted()) \(foodWithPortion.portionName)")
                    .font(.caption)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserMealsDatabase.self) {UserMealsDatabaseForScreenshots()}
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}
    let _ = swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        EditMealView()
    }
}
