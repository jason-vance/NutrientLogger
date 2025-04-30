//
//  LogMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import SwiftUI
import SwinjectAutoregistration

struct LogMealView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    let meal: Meal
    
    @State private var prototypeFoods: [FoodItem] = []
    @State private var foods: [FoodItem] = []
    
    @State private var portionAmountValue: Double = 1
    @State private var portionAmountFormatter: NumberFormatter = {
        var nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = ""
        return nf
    }()
    
    @State private var selectedMealTime: MealTime = .none
    @State private var logDate: SimpleDate = .today
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @Inject private var remoteDatabase: RemoteDatabase
    
    private var portionGrams: String {
        var grams = 0.0

        for food in foods {
            grams += (food.amount * food.gramWeight)
        }
        return "(\(grams.formatted(maxDigits: 2))g)"
    }
    
    private var portionValue: String {
        "\(portionAmountValue.formatted(maxDigits: 2)) \(meal.name)"
    }
    
    private var displayNutrients: [Nutrient] {
        return foods
            .flatMap { (food: FoodItem) in food.nutrientGroups }
            .flatMap { (group: NutrientGroup) in group.nutrients }
            .reduce(into: [String:Nutrient]()) { result, nutrient in
                if nutrient.amount > 0 {
                    if let currentNutrient = result[nutrient.fdcNumber] {
                        let newAmount = currentNutrient.amount + nutrient.amount
                        result[nutrient.fdcNumber] = currentNutrient.withAmount(newAmount)
                    } else {
                        result[nutrient.fdcNumber] = nutrient
                    }
                }
            }
            .map { $0.value }
    }
        
    private var isMealTimeValid: Bool {
        selectedMealTime != .none
    }
    
    private var canSave: Bool {
        isMealTimeValid
    }
    
    private func fetchRemoteFoodsAndPortions() {
        Task {
            do {
                var foods: [FoodItem] = []
                for foodAndPortion in meal.foodsWithPortions {
                    if let food = try remoteDatabase.getFood(String(foodAndPortion.foodFdcId)) {
                        foods.append(food)
                    }
                }
                
                self.prototypeFoods = foods
                applyPortions()
            } catch {
                print("Failed to fetch remote foods: \(error.localizedDescription)")
            }
        }
    }
    
    private func applyPortions() {
        Task {
            let portions: [String:Meal.FoodWithPortion] = meal
                .foodsWithPortions.reduce(into: [:]) { result, foodAndPortion in
                    result[String(foodAndPortion.foodFdcId)] = foodAndPortion
                }
            
            self.foods = prototypeFoods.compactMap { food in
                if let prototypePortion = portions[String(food.fdcId)] {
                    let portion = Portion(
                        name: prototypePortion.portionName,
                        amount: prototypePortion.portionAmount * portionAmountValue,
                        gramWeight: prototypePortion.portionGramWeight
                    )
                    
                    do {
                        return try food.applyingPortion(portion)
                    } catch {
                        print("Failed to apply portion. Error: \(error.localizedDescription)")
                    }
                } else {
                    print("No prototype portion found for \(food.fdcId)")
                }
                return nil
            }
        }
    }
    
    private func saveMeal() {
        Task {
            let foodSaver = FoodSaver.forConsumedFoods(modelContext: modelContext)
            let portions: [String:Meal.FoodWithPortion] = meal
                .foodsWithPortions.reduce(into: [:]) { result, foodAndPortion in
                    result[String(foodAndPortion.foodFdcId)] = foodAndPortion
                }
            
            prototypeFoods.forEach { food in
                if let prototypePortion = portions[String(food.fdcId)] {
                    var food = food
                    food.dateLogged = logDate
                    food.mealTime = selectedMealTime
                    
                    let portion = Portion(
                        name: prototypePortion.portionName,
                        amount: prototypePortion.portionAmount * portionAmountValue,
                        gramWeight: prototypePortion.portionGramWeight
                    )

                    do {
                        try foodSaver.saveFoodItem(food, portion)
                    } catch {
                        let message = "Failed to save meal foods: \(error.localizedDescription)"
                        print(message)
                        show(alert: message)
                    }
                } else {
                    print("No prototype portion found for \(food.fdcId)")
                }
            }
            
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func show(alert message: String) {
        showAlert = true
        alertMessage = message
    }
    
    var body: some View {
        List {
            MealName()
            DateField()
            MealTimeField()
            PortionAmountField()
            
            NativeAdListRow(ad: $ad, size: .medium)

            FoodsSection()

            NutritionFactsSection(
                nutrients: displayNutrients,
                portionGrams: portionGrams,
                portionValue: portionValue
            )
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listDefaultModifiers()
        .environment(\.defaultMinListRowHeight, 1)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .onChange(of: portionAmountValue) { applyPortions() }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .alert(alertMessage, isPresented: $showAlert) { }
        .onAppear { fetchRemoteFoodsAndPortions() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Log Meal")
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
            presentationMode.wrappedValue.dismiss()
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
    
    @ViewBuilder private func MealName() -> some View {
        HStack {
            Text(meal.name)
                .font(.title.bold())
                .listRowDefaultModifiers()
            Spacer()
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func PortionAmountField() -> some View {
        HStack {
            Text("Portion Amount")
            Spacer()
            TextField(
                "Portion Amount",
                value: .init(
                    get: { portionAmountValue },
                    set: { portionAmountValue = $0 <= 0 ? 1 : $0 }
                ),
                formatter: portionAmountFormatter
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .foregroundStyle(Color.accentColor)
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func DateField() -> some View {
        HStack {
            Text("Date")
            Spacer()
            Button {
                
            } label: {
                Text(logDate.formatted())
                    .bold()
            }
            .overlay{
                DatePicker(
                    "",
                    selection: .init(
                        get: { logDate.toDate() ?? .now },
                        set: { logDate = SimpleDate(date: $0)! }
                    ),
                    displayedComponents: [.date]
                )
                .blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func MealTimeField() -> some View {
        HStack {
            Text("Meal Time")
            Spacer()
            Menu {
                ForEach(MealTime.validFields, id: \.self) { mealTime in
                    Button(mealTime.rawValue) {
                        selectedMealTime = mealTime
                    }
                }
            } label: {
                Text(selectedMealTime.rawValue)
                    .bold()
                    .underlined(!canSave, color: .red, lineWidth: 1)
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FoodsSection() -> some View {
        Section(header: Text("Foods")) {
            ForEach(meal.foodsWithPortions) { foodWithPortion in
                FoodRow(foodWithPortion)
            }
        }
    }
    
    @ViewBuilder private func FoodRow(_ foodWithPortion: Meal.FoodWithPortion) -> some View {
        VStack {
            HStack {
                Text(foodWithPortion.foodName)
                Spacer()
            }
            .bold()
            HStack {
                Text("\(foodWithPortion.portionAmount.formatted(maxDigits: 2)) \(foodWithPortion.portionName)")
                Spacer()
            }
            .font(.footnote)
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    
    NavigationStack {
        LogMealView(meal: .sample)
    }
    .environmentObject(AdProviderFactory.forDev)
}
