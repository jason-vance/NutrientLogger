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
    
    @EnvironmentObject private var dataController: DataController

    let meal: Meal
    
    /// Each of the meal's foods with the portion saved for it, in the meal's order. Kept as pairs
    /// so a food listed twice (oil for the pan and for the dressing) keeps both portions.
    @State private var prototypeFoods: [(food: FoodItem, portion: Meal.FoodWithPortion)] = []
    @State private var foods: [FoodItem] = []
    
    @State private var portionAmountValue: Double = 1
    // Typed text, read on every keystroke so tapping Add mid-edit saves what's on screen.
    @State private var amountText: String = "1"
    @State private var amountSelection: TextSelection?
    @FocusState private var isAmountFocused: Bool
    
    @State private var selectedMealTime: MealTime = .forCurrentTime()
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
    
    private var isBatchDish: Bool { meal.servings > 1 }

    private var portionValue: String {
        let amount = portionAmountValue.formatted(maxDigits: 2)
        guard isBatchDish else { return "\(amount) \(meal.name)" }
        return "\(amount) serving\(portionAmountValue == 1 ? "" : "s") of \(meal.name)"
    }

    /// How much of each saved portion to log: the servings eaten, out of what the dish makes.
    private var portionMultiplier: Double {
        Meal.portionMultiplier(servingsEaten: portionAmountValue, servingsMade: meal.servings)
    }

    private func scaledPortion(_ saved: Meal.FoodWithPortion) -> Portion {
        Portion(
            name: saved.portionName,
            amount: saved.portionAmount * portionMultiplier,
            gramWeight: saved.portionGramWeight
        )
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

    /// Quick picks: a share of a plain meal, or whole servings of a batch dish.
    private var quickAmounts: [Double] {
        isBatchDish ? [1, 2, 3, 4] : [0.5, 1, 1.5, 2]
    }

    private var calories: Double? {
        displayNutrients.first { $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Energy_KCal }?.amount
    }

    private var logButtonTitle: String {
        canSave ? "Add to \(selectedMealTime.rawValue)" : "Pick a meal"
    }

    /// "3 foods · 540 kcal · Today"
    private var logButtonDetail: String? {
        var parts: [String] = []
        if isBatchDish {
            parts.append("\(portionAmountValue.formatted(maxDigits: 2)) serving\(portionAmountValue == 1 ? "" : "s")")
        } else {
            parts.append("\(meal.foodsWithPortions.count) food\(meal.foodsWithPortions.count == 1 ? "" : "s")")
        }
        if let calories {
            parts.append("\(calories.formatted(maxDigits: 0)) kcal")
        }
        parts.append(logDate.formatted())
        return parts.joined(separator: " · ")
    }

    private func setAmount(_ amount: Double) {
        portionAmountValue = amount
        amountText = LogPortionDefaults.label(for: amount)
    }
    
    private func fetchRemoteFoodsAndPortions() {
        Task {
            do {
                var foods: [(food: FoodItem, portion: Meal.FoodWithPortion)] = []
                for foodAndPortion in meal.foodsWithPortions {
                    if let food = try remoteDatabase.getFood(String(foodAndPortion.foodFdcId)) {
                        foods.append((food, foodAndPortion))
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
        foods = prototypeFoods.compactMap { pair in
            do {
                return try pair.food.applyingPortion(scaledPortion(pair.portion))
            } catch {
                print("Failed to apply portion. Error: \(error.localizedDescription)")
                return nil
            }
        }
    }

    private func saveMeal() {
        Task {
            let foodSaver = FoodSaver.forConsumedFoods(modelContext: modelContext)

            for pair in prototypeFoods {
                var food = pair.food
                food.dateLogged = logDate
                food.mealTime = selectedMealTime

                do {
                    try foodSaver.saveFoodItem(food, scaledPortion(pair.portion))
                } catch {
                    let message = "Failed to save meal foods: \(error.localizedDescription)"
                    print(message)
                    show(alert: message)
                }
            }

            presentationMode.wrappedValue.dismiss()

            DispatchQueue.main.async {
                dataController.updateDailySummary()
            }
        }
    }

    private func show(alert message: String) {
        showAlert = true
        alertMessage = message
    }
    
    var body: some View {
        List {
            PremiumCTARow(trigger: .smartPaywall, size: .small)
            MealName()
            LogDetailsCard()
            FoodsCard()
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
        .safeAreaInset(edge: .bottom) {
            LogActionButton(title: logButtonTitle, detail: logButtonDetail, isEnabled: canSave) { saveMeal() }
        }
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: portionAmountValue) { applyPortions() }
        .onChange(of: amountText) { _, text in
            if let value = LogPortionDefaults.parseAmount(text), value > 0, value != portionAmountValue {
                portionAmountValue = value
            }
        }
        .onChange(of: isAmountFocused) { _, isFocused in
            guard isFocused else { return }
            // Select the whole number so typing replaces it.
            DispatchQueue.main.async {
                amountSelection = TextSelection(range: amountText.startIndex..<amountText.endIndex)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) { }
        .onAppear { fetchRemoteFoodsAndPortions() }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Log Meal")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "arrow.backward")
            }
        }
    }

    @ViewBuilder private func MealName() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.name)
                .font(.title.bold())
            if let makes = Meal.makesText(servings: meal.servings) {
                Text(makes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func LogDetailsCard() -> some View {
        VStack(spacing: 0) {
            LogDateField(logDate: $logDate)
            Divider().padding(.horizontal)
            LogMealTimeField(mealTime: $selectedMealTime)
            Divider().padding(.horizontal)
            AmountField()
        }
        .padding(.vertical, 4)
        .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
    }

    /// How much of the meal: a share of it (½, 1, 1½), or how many servings of a batch dish.
    @ViewBuilder private func AmountField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                LogFieldLabel(isBatchDish ? "Servings" : "Amount")
                Spacer()
                TextField("Amount", text: $amountText, selection: $amountSelection)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .multilineTextAlignment(.center)
                    .bold()
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 80, height: 34)
                    .background(Capsule().fill(Color.gray.opacity(0.18)))
                    .overlay(
                        Capsule().stroke(isAmountFocused ? Color.accentColor : .clear, lineWidth: 1.5)
                    )
            }
            LogPillRow(
                items: quickAmounts,
                labels: quickAmounts.map(LogPortionDefaults.label(for:)),
                isSelected: { $0 == portionAmountValue },
                onSelect: { amount in
                    isAmountFocused = false
                    setAmount(amount)
                }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    /// The foods that will be logged, at the amounts the current servings work out to.
    @ViewBuilder private func FoodsCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LogFieldLabel("Foods")
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 4)
            ForEach(Array(meal.foodsWithPortions.enumerated()), id: \.offset) { index, foodWithPortion in
                if index > 0 {
                    Divider().padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(foodWithPortion.foodName)
                        .lineLimit(2)
                    Text(LogPortionDefaults.summary(
                        amount: foodWithPortion.portionAmount * portionMultiplier,
                        portionName: foodWithPortion.portionName
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 4)
        .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
        .animation(.snappy, value: portionAmountValue)
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    
    NavigationStack {
        LogMealView(meal: .sample)
    }
}
