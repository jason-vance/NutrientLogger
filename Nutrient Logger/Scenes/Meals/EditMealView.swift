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
    
    @Inject var analytics: UserMealsAnalytics
    @Inject private var remoteDatabase: RemoteDatabase
    
    private let meal: Meal?
    @State private var isPrepopulated: Bool = false
    @State var mealName: String = ""
    @State var foodsWithPortions: [Meal.FoodWithPortion] = []
    @State private var servings: Double = 1
    /// Calories for the whole meal, worked out from its foods.
    @State private var totalCalories: Double?

    private static let servingOptions: [Double] = [1, 2, 3, 4, 6, 8, 10, 12]
    
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
            return meal.name != mealName || meal.foodsWithPortions != foodsWithPortions || meal.servings != servings
        } else {
            return !mealName.isEmpty || hasFoods || servings != 1
        }
    }
    
    private func prepopulateMeal() {
        if let meal = meal, !isPrepopulated {
            self.mealName = meal.name
            self.foodsWithPortions = meal.foodsWithPortions
            self.servings = meal.servings

            isPrepopulated = true
        }
    }
    
    private func saveMeal() {
        if let meal = meal {
            meal.name = mealName
            meal.foodsWithPortions = foodsWithPortions
            meal.servings = servings
        } else {
            let meal = Meal(name: mealName)
            meal.addFoods(foodsWithPortions)
            meal.servings = servings
            modelContext.insert(meal)
            analytics.mealCreated()
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private var saveButtonTitle: String {
        if mealName.trimmingCharacters(in: .whitespaces).isEmpty { return "Name this meal" }
        if !hasFoods { return "Add a food" }
        return meal == nil ? "Save Meal" : "Save Changes"
    }

    /// "4 foods · 540 kcal per serving"
    private var saveButtonDetail: String? {
        guard hasFoods else { return nil }
        var parts = ["\(foodsWithPortions.count) food\(foodsWithPortions.count == 1 ? "" : "s")"]
        if let totalCalories {
            let perServing = totalCalories / max(servings, 1)
            parts.append("\(perServing.formatted(maxDigits: 0)) kcal" + (servings > 1 ? " per serving" : ""))
        }
        return parts.joined(separator: " · ")
    }

    private func updateCalories() async {
        var total = 0.0
        for item in foodsWithPortions {
            let portion = Portion(name: item.portionName, amount: item.portionAmount, gramWeight: item.portionGramWeight)
            guard let food = try? remoteDatabase.getFood(String(item.foodFdcId))?.applyingPortion(portion) else { continue }
            total += food.nutrientGroups.flatMap(\.nutrients)
                .first { $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Energy_KCal }?.amount ?? 0
        }
        totalCalories = foodsWithPortions.isEmpty ? nil : total
    }

    private var canSave: Bool {
        !mealName.isEmpty
        && hasFoods
    }
    
    var body: some View {
        List {
            PremiumCTARow(trigger: .smartPaywall, size: .small)
            NameField()
            ServingsSection()
            FoodsSection()
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .safeAreaInset(edge: .bottom) {
            LogActionButton(title: saveButtonTitle, detail: saveButtonDetail, isEnabled: canSave) { saveMeal() }
        }
        .toolbar(.hidden, for: .tabBar)
        .task(id: foodsWithPortions.map(\.foodFdcId)) { await updateCalories() }
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
    
    @ViewBuilder private func NameField() -> some View {
        Section(header: Text("Meal Name")) {
            TextField(
                "Meal Name",
                text: $mealName,
                axis: .vertical,
            )
            .foregroundStyle(Color.accentColor)
        }
        .listRowDefaultModifiers()
    }
    
    /// How many servings the foods make, as one-tap pills. 1 is a plain meal; more is a batch dish.
    @ViewBuilder private func ServingsSection() -> some View {
        let options = Self.servingOptions.contains(servings)
            ? Self.servingOptions
            : (Self.servingOptions + [servings]).sorted()
        Section {
            LogPillRow(
                items: options,
                labels: options.map { $0.formatted(maxDigits: 2) },
                isSelected: { $0 == servings },
                onSelect: { option in withAnimation(.snappy) { servings = option } }
            )
            .listRowDefaultModifiers()
        } header: {
            Text("Makes how many servings?")
        } footer: {
            Text("Cooking a dish? Add the ingredients for the whole batch, then pick how many servings it makes. You'll log it one serving at a time.")
        }
    }

    @ViewBuilder private func FoodsSection() -> some View {
        Section(header: Text("Foods")) {
            ForEach(foodsWithPortions) { food in
                FoodRow(food)
            }
            .onDelete {
                foodsWithPortions.remove(atOffsets: $0)
            }
            Button {
                showFoodSearch = true
            } label: {
                Label(hasFoods ? "Add Another Food" : "Add a Food", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func FoodRow(_ foodWithPortion: Meal.FoodWithPortion) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(foodWithPortion.foodName)
                .lineLimit(2)
            Text(LogPortionDefaults.summary(amount: foodWithPortion.portionAmount, portionName: foodWithPortion.portionName))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}
