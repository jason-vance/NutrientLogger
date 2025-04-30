//
//  EditMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: Add some Nutrition Facts?
struct EditMealView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject var analytics: UserMealsAnalytics
    
    private let meal: Meal?
    @State private var isPrepopulated: Bool = false
    @State var mealName: String = ""
    @State var foodsWithPortions: [Meal.FoodWithPortion] = []
    
    @State private var showFoodSearch: Bool = false
    @State private var showDiscardDialog: Bool = false

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
    
    private var hasChanges: Bool {
        if let meal = meal {
            return meal.name != mealName || meal.foodsWithPortions != foodsWithPortions
        } else {
            return !mealName.isEmpty || hasFoods
        }
    }
    
    private func prepopulateMeal() {
        if let meal = meal, !isPrepopulated {
            self.mealName = meal.name
            self.foodsWithPortions = meal.foodsWithPortions
            
            isPrepopulated = true
        }
    }
    
    private func saveMeal() {
        if let meal = meal {
            meal.name = mealName
            meal.foodsWithPortions = foodsWithPortions
        } else {
            let meal = Meal(name: mealName)
            meal.addFoods(foodsWithPortions)
            modelContext.insert(meal)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private var canSave: Bool {
        !mealName.isEmpty
        && hasFoods
    }
    
    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .medium)
            NameField()
            FoodsSection()
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .overlay(alignment: .bottomTrailing) {
            AddFoodButton()
        }
        .scrollDismissesKeyboard(.immediately)
        .animation(.snappy, value: meal)
        .animation(.snappy, value: foodsWithPortions)
        .sheet(isPresented: $showFoodSearch) {
            NavigationStack {
                FoodSearchView(
                    searchFunction: .addFoodToMeal,
                    askForDateAndMealTime: false
                ) { food, portion in
                    foodsWithPortions.append(.init(food: food, portion: portion))
                    showFoodSearch = false
                }
            }
        }
        .onAppear { prepopulateMeal() }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .confirmationDialog(
            "Discard Changes?\n\nAre you sure you want to leave? Any unsaved changes will be lost.",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible,
        ) {
            Button("Discard", role: .destructive) { presentationMode.wrappedValue.dismiss() }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(mealName)
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            SaveButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button {
            if hasChanges {
                showDiscardDialog = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        } label: {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func SaveButton() -> some View {
        Button {
            saveMeal()
        } label: {
            Image(systemName: "checkmark")
        }
        .disabled(!canSave)
    }
    
    @ViewBuilder private func AddFoodButton() -> some View {
        ButtonFab(systemName: "plus") {
            showFoodSearch = true
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
    let _ = swinjectContainer.autoregister(UserMealsAnalytics.self) {MockUserMealsAnalytics()}
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        EditMealView()
    }
    .environmentObject(AdProviderFactory.forDev)
}
