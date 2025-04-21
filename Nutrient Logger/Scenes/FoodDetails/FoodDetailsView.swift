//
//  FoodDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: Add a toast-like notification for when a food is successfully saved
//TODO: Add a mealTime parameter (like MyFitnessPal)
struct FoodDetailsView: View {
    
    enum Mode {
        case searchResult(fdcId: Int)
        case loggedFood(food: ConsumedFood)
        
        var isLoggedFood: Bool {
            switch self {
            case .loggedFood: return true
            default: return false
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.presentationMode) var presentationMode

    @State private var prototypeFood: FoodItem?
    @State private var food: FoodItem?
    
    @State private var portions: [Portion] = []
    @State private var selectedPortion: Portion?
    @State private var portionAmountValue: Double = 1
    @State private var portionAmountFormatter: NumberFormatter = {
        var nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = ""
        return nf
    }()
    
    @State private var selectedMealTime: MealTime = .none
    
    @State private var logDate: SimpleDate = .today

    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    
    let mode: Mode
    let askForDateAndMealTime: Bool
    let onFoodSaved: (FoodItem, Portion) throws -> Void

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary

    private var fdcId: Int {
        switch mode {
        case .searchResult(let fdcId):
            return fdcId
        case .loggedFood(let food):
            return food.fdcId
        }
    }
    
    private var user: User { userService.currentUser }
    
    private func show(alert: String) {
        showAlert = true
        alertTitle = alert
    }
    
    private func fetchFoodAndPortions() {
        do {
            prototypeFood = try remoteDatabase.getFood(String(fdcId))
            if let food = prototypeFood {
                portions = try remoteDatabase.getPortions(food)
                selectedPortion = portions.first
                
                if let portion = selectedPortion {
                    self.food = try food.applyingPortion(portion)
                }
            } else {
                print("Failed to find remote food with id \(fdcId)")
            }
        } catch {
            print("Failed to fetch remote food with id \(fdcId): \(error.localizedDescription)")
        }
    }

    private func deleteFood() {
        guard let consumedFood = {
            switch mode {
            case .loggedFood(let food): return food
            default: return nil
            }
        }() else {
            show(alert: "Failed to delete. Food doesn't appear to be a logged food")
            return
        }
        
        modelContext.delete(consumedFood)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func applyPortion() {
        Task {
            if let portion = selectedPortion {
                selectedPortion = .init(
                    name: portion.name,
                    amount: portionAmountValue,
                    gramWeight: portion.gramWeight
                )
                
                do {
                    food = try prototypeFood?.applyingPortion(selectedPortion!)
                } catch {
                    print("Failed to apply portion. Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var portionGrams: String {
        guard let food = food, food.amount > 0 else {
            return "(100g)"
        }
        
        let number = (food.amount * food.gramWeight).formatted(maxDigits: 2)
        return "(\(number)g)"
    }
    
    private var portionValue: String {
        guard let food = food, food.amount > 0 else {
            return ""
        }
        
        let number = food.amount.formatted(maxDigits: 2)
        return "\(number) \(food.portionName)"
    }
    
    private var displayNutrients: [Nutrient] {
        food?.nutrientGroups.flatMap { group in
            group.nutrients.compactMap { nutrient in
                (nutrient.amount > 0) ? nutrient : nil
            }
        } ?? []
    }
    
    private var isMealTimeValid: Bool {
        !askForDateAndMealTime || selectedMealTime != .none
    }
    
    private var canSave: Bool {
        isMealTimeValid
    }
    
    private func saveFood() {
        guard var food = prototypeFood else {
            show(alert: "`prototypeFood` is nil")
            return
        }
        food.dateLogged = logDate
        food.mealTime = selectedMealTime
        
        let selectedPortion = selectedPortion ?? .defaultPortion
        let portion = Portion(
            name: selectedPortion.name,
            amount: portionAmountValue,
            gramWeight: selectedPortion.gramWeight
        )
        
        do {
            try onFoodSaved(food, portion)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save food item: \(error.localizedDescription)")
        }
    }
    
    private func populateFieldsIfNeeded() {
        if case .loggedFood(let food) = mode {
            self.logDate = food.dateLogged
            self.selectedMealTime = food.mealTime
            self.portionAmountValue = food.portion.amount
            self.selectedPortion = food.portion
        }
    }
    
    init(
        mode: Mode,
        askForDateAndMealTime: Bool = true,
        onFoodSaved: @escaping (FoodItem, Portion) throws -> Void
    ) {
        self.mode = mode
        self.askForDateAndMealTime = askForDateAndMealTime
        self.onFoodSaved = onFoodSaved
    }
    
    var body: some View {
        List {
            FoodName()
            if askForDateAndMealTime {
                DateField()
                MealTimeField()
            }
            PortionField()
            PortionAmountField()
            
            AdRow()
            
            if !displayNutrients.isEmpty {
                NutritionFactsSection(
                    nutrients: displayNutrients,
                    portionGrams: portionGrams,
                    portionValue: portionValue
                )
            }
            
            if mode.isLoggedFood {
                DeleteButton()
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listDefaultModifiers()
        .environment(\.defaultMinListRowHeight, 1)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .onAppear { fetchFoodAndPortions() }
        .onAppear { populateFieldsIfNeeded() }
        .onChange(of: portionAmountValue) { applyPortion() }
        .confirmationDialog(
            "Delete Food?\n\nAre you sure you want to delete \"\(food?.name ?? "this food")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete", role: .destructive) { deleteFood() }
            Button("Cancel", role: .cancel) { }
        }
        .alert(alertTitle, isPresented: $showAlert) { }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Food Details")
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
    
    @ViewBuilder private func DeleteButton() -> some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack{
                Spacer()
                Text("Delete")
                    .foregroundStyle(.red)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func SaveButton() -> some View {
        Button {
            saveFood()
        } label: {
            Image(systemName: "checkmark")
        }
        .disabled(!canSave)
    }
    
    @ViewBuilder private func FoodName() -> some View {
        HStack {
            Text(food?.name ?? "Food Name")
                .font(.title.bold())
                .listRowDefaultModifiers()
            Spacer()
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func PortionField() -> some View {
        HStack {
            Text("Portion")
            Spacer()
            Menu {
                ForEach(portions, id: \.self) { portion in
                    Button(portion.name) {
                        selectedPortion = portion
                        applyPortion()
                    }
                }
            } label: {
                Text(selectedPortion?.name ?? "Select Portion")
                    .bold()
            }
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
    
    @ViewBuilder private func AdRow() -> some View {
        SimpleNativeAdView(size: .small)
            .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) {
        MockNutrientLoggerAnalytics()
    }
    let _ = swinjectContainer.autoregister(UserService.self) {
        UserServiceForScreenshots()
    }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {
        UsdaNutrientRdiLibrary.create()
    }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {
        RemoteDatabaseForScreenshots()
    }
    
    NavigationStack {
        FoodDetailsView(
            mode: .searchResult(fdcId: 1234),
            onFoodSaved: { _, _ in }
        )
    }
}
