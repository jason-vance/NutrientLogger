//
//  FoodDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Add a toast-like notification for when a food is successfully saved
struct FoodDetailsView: View {
    
    enum UIConsts {
        public static let lineWidth_Thin: CGFloat = 1
        public static let lineWidth_Regular: CGFloat = 2
        public static let lineWidth_Thick: CGFloat = 6
        public static let lineWidth_ExtraThick: CGFloat = 14
        public static let margin: CGFloat = 8

        public static let fontSize_Name: CGFloat = 48
        public static let fontSize_Calories: CGFloat = 38
        public static let fontSize_Portion: CGFloat = 28
        public static let fontSize_Nutrient: CGFloat = 18

        public static var outlineMargin: CGFloat { margin }
        public static var outlineWidth: CGFloat { lineWidth_Regular }
        public static var thinLineWidth: CGFloat { lineWidth_Thin }

        public static var textMargin: CGFloat { 2 * margin + outlineWidth }
        public static var nameFontSize: CGFloat { fontSize_Name }
        public static var portionFontSize: CGFloat { fontSize_Portion }
        public static var caloriesFontSize: CGFloat { fontSize_Calories }
        public static var nutrientFontSize: CGFloat { fontSize_Nutrient }
    }
    
    enum Mode {
        case searchResult
        case loggedFood
    }
    
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
    
    //TODO: MVP: Intelligently choose the initial meal time
    @State private var selectedMealTime: MealTime = .breakfast
    @State private var logDate: SimpleDate = .today

    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    
    let foodId: Int
    let mode: Mode
    
    private let localDatabase = swinjectContainer~>LocalDatabase.self
    private let remoteDatabase = swinjectContainer~>RemoteDatabase.self
    
    private let user = (swinjectContainer~>UserService.self).currentUser
    private let rdiLibrary = swinjectContainer~>NutrientRdiLibrary.self
    
    private let foodSaver = swinjectContainer~>FoodSaver.self
    
    private func show(alert: String) {
        showAlert = true
        alertTitle = alert
    }
    
    private func fetchLoggedFoodAndPortions() {
        do {
            food = try localDatabase.getFood(foodId)
        } catch {
            print("Failed to fetch logged food with id \(foodId): \(error.localizedDescription)")
        }
    }
    
    private func fetchRemoteFoodAndPortions() {
        do {
            prototypeFood = try remoteDatabase.getFood(String(foodId))
            if let food = prototypeFood {
                portions = try remoteDatabase.getPortions(food)
                selectedPortion = portions.first
                
                if let portion = selectedPortion {
                    self.food = try food.applyingPortion(portion)
                }
            } else {
                print("Failed to find remote food with id \(foodId)")
            }
        } catch {
            print("Failed to fetch remote food with id \(foodId): \(error.localizedDescription)")
        }
    }

    private func fetchFoodAndPortions() {
        if isLoggedFood {
            fetchLoggedFoodAndPortions()
        } else {
            fetchRemoteFoodAndPortions()
        }
    }
    
    private func deleteFood() {
        guard let food = self.food else {
            show(alert: "Failed to delete. Food doesn't appear to exist")
            return
        }
        
        do {
            try localDatabase.deleteFood(food)
            presentationMode.wrappedValue.dismiss()
        } catch {
            show(alert: "Could not delete food: \(error.localizedDescription)")
            if let analytics = swinjectContainer.resolve(NutrientLoggerAnalytics.self) {
                analytics.errorDeletingFood(error)
            }
        }
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
    
    private var isLoggedFood: Bool {
        mode == .loggedFood
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
    
    private func removeNutrient(_ nutrients: inout [Nutrient], _ fdcNumber: String) -> Nutrient? {
        guard let nutrient = nutrients.first(where: { $0.fdcNumber == fdcNumber })
        else {
            return nil
        }

        nutrients = nutrients.filter { $0.fdcId != nutrient.fdcId }
        return nutrient
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
            try foodSaver.saveFoodItem(food, portion)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save food item: \(error.localizedDescription)")
        }
    }
    
    init(foodId: Int, mode: Mode) {
        self.foodId = foodId
        self.mode = mode
    }
    
    var body: some View {
        var nutrients = displayNutrients
        
        List {
            FoodName()
            DateField()
            MealTimeField()
            PortionField()
            PortionAmountField()
            
            NutritionFactsCap(isTop: true)
            
//            NutritionFactsFoodName()
//            NutritionFactsLine(UIConsts.lineWidth_Thin)
            NutritionFactsPortion()
            NutritionFactsLine(UIConsts.lineWidth_ExtraThick)
            
            Calories(&nutrients)
            Energy(&nutrients)
            WaterEtc(&nutrients)
            Alcohol(&nutrients)
            Ash(&nutrients)
            FattyNutrients(&nutrients)
            Sodium(&nutrients)
            Carbohydrates(&nutrients)
            Protein(&nutrients)
            NutritionFactsLine(UIConsts.lineWidth_ExtraThick)
            
            VitaminA(&nutrients)
            VitaminB(&nutrients)
            VitaminC(&nutrients)
            VitaminD(&nutrients)
            VitaminE(&nutrients)
            VitaminK(&nutrients)
            Minerals(&nutrients)
            Folate(&nutrients)
            Choline(&nutrients)
            OtherVitamins(&nutrients)
            OtherVarious(&nutrients)
            Phytosterols(&nutrients)
            OtherAcids(&nutrients)
            AminoAcids(&nutrients)
            FattyAcids(&nutrients)
            
            OtherNutrients(&nutrients)
            
            NutritionFactsCap(isTop: false)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listDefaultModifiers()
        .environment(\.defaultMinListRowHeight, 1)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .onAppear { fetchFoodAndPortions() }
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
            if mode == .searchResult {
                SaveButton()
            } else {
                DeleteButton()
            }
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
            Image(systemName: "trash")
        }
    }
    
    @ViewBuilder private func SaveButton() -> some View {
        Button {
            saveFood()
        } label: {
            Image(systemName: "checkmark")
        }
    }
    
    @ViewBuilder private func FoodName() -> some View {
        HStack {
            Text(food?.name ?? "Food Name")
                .font(.title.bold())
                .listRowDefaultModifiers()
            Spacer()
        }
    }
    
    @ViewBuilder private func PortionField() -> some View {
        HStack {
            Text("Portion")
            Spacer()
            SwiftUI.Menu {
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
            SwiftUI.Menu {
                ForEach(MealTime.validFields, id: \.self) { mealTime in
                    Button(mealTime.rawValue) {
                        selectedMealTime = mealTime
                    }
                }
            } label: {
                Text(selectedMealTime.rawValue)
                    .bold()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func NutritionFactsCap(isTop: Bool) -> some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 2)
            .padding(.top, (isTop) ? UIConsts.outlineMargin : 0)
            .padding(.bottom, (isTop) ? 0 : UIConsts.outlineMargin)
            .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsFoodName() -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
            Text(food?.name ?? "Food Name")
                .font(.system(size: UIConsts.nameFontSize, weight: .bold))
            Spacer()
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsLine(_ width: CGFloat) -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            Spacer()
            Rectangle()
                .frame(height: width)
                .padding(.vertical, 2)
            Spacer()
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsPortion() -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            VStack {
                HStack {
                    Text("Portion size")
                        .font(.system(size: UIConsts.portionFontSize).bold())
                    Spacer()
                    Text(portionGrams)
                        .font(.system(size: UIConsts.portionFontSize).bold())
                }
                HStack {
                    Spacer()
                    Text(portionValue)
                        .font(.system(size: UIConsts.portionFontSize).bold())
                }
            }
            .padding(.leading, 0.1)
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func Calories(_ nutrients: inout [Nutrient]) -> some View {
        let calories = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Energy_KCal)
        
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            VStack {
                HStack {
                    Text("Amount per portion")
                        .font(.system(size: UIConsts.nutrientFontSize).bold())
                    Spacer()
                }
                HStack {
                    Text("Calories")
                        .font(.system(size: UIConsts.caloriesFontSize).bold())
                    Spacer()
                    Text(calories?.amount.formatted(maxDigits: 1) ?? "??")
                        .font(.system(size: UIConsts.caloriesFontSize).bold())
                }
            }
            .padding(.horizontal, 0.1)
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
        
        NutritionFactsLine(UIConsts.lineWidth_Thick)
    }
    
    @ViewBuilder private func Energy(_ nutrients: inout [Nutrient]) -> some View {
        let energyKj = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Energy_Kj)
        let energyGeneralFactors = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterGeneralFactors)
        let energySpecificFactors = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterSpecificFactors)
        
        if let energyKj = energyKj {
            NutrientRow(energyKj, isNameBold: true)
        }
        if let energyGeneralFactors = energyGeneralFactors {
            NutrientRow(energyGeneralFactors, isNameBold: true)
        }
        if let energySpecificFactors = energySpecificFactors {
            NutrientRow(energySpecificFactors, isNameBold: true)
        }
    }
    
    @ViewBuilder private func WaterEtc(_ nutrients: inout [Nutrient]) -> some View {
        let water = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Water)
        let nitrogen = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Nitrogen)
        let specificGravity = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_SpecificGravity)

        if let water = water {
            NutrientRow(water, isNameBold: true)
        }
        if let nitrogen = nitrogen {
            NutrientRow(nitrogen, isNameBold: true)
        }
        if let specificGravity = specificGravity {
            NutrientRow(specificGravity, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Alcohol(_ nutrients: inout [Nutrient]) -> some View {
        let alcohol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Alcohol_Ethyl)

        if let alcohol = alcohol {
            NutrientRow(alcohol, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Ash(_ nutrients: inout [Nutrient]) -> some View {
        let ash = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Ash)

        if let ash = ash {
            NutrientRow(ash, isNameBold: true)
        }
    }
    
    @ViewBuilder private func FattyNutrients(_ nutrients: inout [Nutrient]) -> some View {
        let totalFatNlea = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_TotalFatNLEA)
        let totalFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat)
        let saturatedFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalSaturated)
        let monounsaturatedFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalMonounsaturated)
        let polyunsaturatedFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalPolyunsaturated)
        let transFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans)
        let transMonoFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Monoenoic)
        let transDiFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Dienoic)
        let transPolyFat = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_PolyEnoic)
        let cholesterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cholesterol)

        if let totalFatNlea = totalFatNlea {
            NutrientRow(totalFatNlea, isNameBold: true)
        }
        if let totalFat = totalFat {
            NutrientRow(totalFat, isNameBold: true)
        }
        if let saturatedFat = saturatedFat {
            NutrientRow(saturatedFat, indentLevel: 1)
        }
        if let monounsaturatedFat = monounsaturatedFat {
            NutrientRow(monounsaturatedFat, indentLevel: 1)
        }
        if let polyunsaturatedFat = polyunsaturatedFat {
            NutrientRow(polyunsaturatedFat, indentLevel: 1)
        }
        if let transFat = transFat {
            NutrientRow(transFat, indentLevel: 1)
        }
        if let transMonoFat = transMonoFat {
            NutrientRow(transMonoFat, indentLevel: 2)
        }
        if let transDiFat = transDiFat {
            NutrientRow(transDiFat, indentLevel: 2)
        }
        if let transPolyFat = transPolyFat {
            NutrientRow(transPolyFat, indentLevel: 2)
        }
        if let cholesterol = cholesterol {
            NutrientRow(cholesterol, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Sodium(_ nutrients: inout [Nutrient]) -> some View {
        let sodium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sodium_Na)

        if let sodium = sodium {
            NutrientRow(sodium, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Carbohydrates(_ nutrients: inout [Nutrient]) -> some View {
        let carbohydrateOther = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_Other)
        let carbohydrateDiff = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference)
        let carbohydrateSum = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_BySummation)
        let starch = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Starch)
        let dietaryFiberAoac = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary_AOAC)
        let dietaryFiber = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary)
        let solubleFiber = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fiber_Soluble)
        let insolubleFiber = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fiber_Insoluble)
        let inulin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Inulin)
        let sugars = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalIncludingNLEA)
        let sugarsAdded = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sugars_Added)
        let nleaSugars = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalNLEA)
        let sucrose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sucrose)
        let glucose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Glucose_Dextrose)
        let fructose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fructose)
        let lactose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Lactose)
        let maltose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Maltose)
        let galactose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Galactose)
        let ribose = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Ribose)
        let totalSugarAlcohols = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_TotalSugarAlcohols)
        let sorbitol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sorbitol)
        let xylitol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Xylitol)
        let inositol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Inositol)

        if let carbohydrateOther = carbohydrateOther {
            NutrientRow(carbohydrateOther, isNameBold: true)
        }
        if let carbohydrateDiff = carbohydrateDiff {
            NutrientRow(carbohydrateDiff, isNameBold: true)
        }
        if let carbohydrateSum = carbohydrateSum {
            NutrientRow(carbohydrateSum, isNameBold: true)
        }
        if let starch = starch {
            NutrientRow(starch, indentLevel: 1)
        }
        if let dietaryFiberAoac = dietaryFiberAoac {
            NutrientRow(dietaryFiberAoac, indentLevel: 1)
        }
        if let dietaryFiber = dietaryFiber {
            NutrientRow(dietaryFiber, indentLevel: 1)
        }
        if let solubleFiber = solubleFiber {
            NutrientRow(solubleFiber, indentLevel: 2)
        }
        if let insolubleFiber = insolubleFiber {
            NutrientRow(insolubleFiber, indentLevel: 2)
        }
        if let inulin = inulin {
            NutrientRow(inulin, indentLevel: 2)
        }
        if let sugars = sugars {
            NutrientRow(sugars, indentLevel: 1)
        }
        if let sugarsAdded = sugarsAdded {
            NutrientRow(sugarsAdded, indentLevel: 2)
        }
        if let nleaSugars = nleaSugars {
            NutrientRow(nleaSugars, indentLevel: 2)
        }
        if let sucrose = sucrose {
            NutrientRow(sucrose, indentLevel: 2)
        }
        if let glucose = glucose {
            NutrientRow(glucose, indentLevel: 2)
        }
        if let fructose = fructose {
            NutrientRow(fructose, indentLevel: 2)
        }
        if let lactose = lactose {
            NutrientRow(lactose, indentLevel: 2)
        }
        if let maltose = maltose {
            NutrientRow(maltose, indentLevel: 2)
        }
        if let galactose = galactose {
            NutrientRow(galactose, indentLevel: 2)
        }
        if let ribose = ribose {
            NutrientRow(ribose, indentLevel: 2)
        }
        if let totalSugarAlcohols = totalSugarAlcohols {
            NutrientRow(totalSugarAlcohols, indentLevel: 1)
        }
        if let sorbitol = sorbitol {
            NutrientRow(sorbitol, indentLevel: 2)
        }
        if let xylitol = xylitol {
            NutrientRow(xylitol, indentLevel: 2)
        }
        if let inositol = inositol {
            NutrientRow(inositol, indentLevel: 1)
        }
    }
    
    @ViewBuilder private func Protein(_ nutrients: inout [Nutrient]) -> some View {
        let protein = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Protein)

        if let protein = protein {
            NutrientRow(protein, isNameBold: true, showDivider: false)
        }
    }
    
    @ViewBuilder private func VitaminA(_ nutrients: inout [Nutrient]) -> some View {
        let vitaminAIU = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU)
        let vitaminARae = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE)
        let retinol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Retinol)
        let betaCarotene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta)
        let cisBetaCarotene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta)
        let transBetaCarotene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta)
        let alphaCarotene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha)
        let cryptoxanthinAlpha = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Alpha)
        let cryptoxanthinBeta = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Beta)

        if let vitaminAIU = vitaminAIU {
            NutrientRow(vitaminAIU)
        }
        if let vitaminARae = vitaminARae {
            NutrientRow(vitaminARae)
        }
        if let retinol = retinol {
            NutrientRow(retinol, indentLevel: 1)
        }
        if let betaCarotene = betaCarotene {
            NutrientRow(betaCarotene, indentLevel: 1)
        }
        if let cisBetaCarotene = cisBetaCarotene {
            NutrientRow(cisBetaCarotene, indentLevel: 1)
        }
        if let transBetaCarotene = transBetaCarotene {
            NutrientRow(transBetaCarotene, indentLevel: 1)
        }
        if let alphaCarotene = alphaCarotene {
            NutrientRow(alphaCarotene, indentLevel: 1)
        }
        if let cryptoxanthinAlpha = cryptoxanthinAlpha {
            NutrientRow(cryptoxanthinAlpha, indentLevel: 1)
        }
        if let cryptoxanthinBeta = cryptoxanthinBeta {
            NutrientRow(cryptoxanthinBeta, indentLevel: 1)
        }
    }
    
    @ViewBuilder private func VitaminB(_ nutrients: inout [Nutrient]) -> some View {
        let thiamin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Thiamin)
        let riboflavin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Riboflavin)
        let niacin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Niacin)
        let pantothenicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid)
        let vitaminB6 = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminB6)
        let biotin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Biotin)
        let vitaminB12 = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminB12)
        let vitaminB12Added = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminB12_Added)

        if let thiamin = thiamin {
            NutrientRow(thiamin)
        }
        if let riboflavin = riboflavin {
            NutrientRow(riboflavin)
        }
        if let niacin = niacin {
            NutrientRow(niacin)
        }
        if let pantothenicAcid = pantothenicAcid {
            NutrientRow(pantothenicAcid)
        }
        if let vitaminB6 = vitaminB6 {
            NutrientRow(vitaminB6)
        }
        if let biotin = biotin {
            NutrientRow(biotin)
        }
        if let vitaminB12 = vitaminB12 {
            NutrientRow(vitaminB12)
        }
        if let vitaminB12Added = vitaminB12Added {
            NutrientRow(vitaminB12Added)
        }
    }
    
    @ViewBuilder private func VitaminC(_ nutrients: inout [Nutrient]) -> some View {
        let vitaminC = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid)

        if let vitaminC = vitaminC {
            NutrientRow(vitaminC)
        }
    }
    
    @ViewBuilder private func VitaminD(_ nutrients: inout [Nutrient]) -> some View {
        let vitaminDIu = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU)
        let vitaminD = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3)
        let vitaminD2 = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2)
        let vitaminDCholecalciferol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminD3_Cholecalciferol)
        let hydroxycholecalciferol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Hydroxycholecalciferol)

        if let vitaminDIu = vitaminDIu {
            NutrientRow(vitaminDIu)
        }
        if let vitaminD = vitaminD {
            NutrientRow(vitaminD)
        }
        if let vitaminD2 = vitaminD2 {
            NutrientRow(vitaminD2)
        }
        if let vitaminDCholecalciferol = vitaminDCholecalciferol {
            NutrientRow(vitaminDCholecalciferol)
        }
        if let hydroxycholecalciferol = hydroxycholecalciferol {
            NutrientRow(hydroxycholecalciferol)
        }
    }
    
    @ViewBuilder private func VitaminE(_ nutrients: inout [Nutrient]) -> some View {
        let vitaminEAdded = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminE_Added)
        let vitaminETocopherol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol)
        let vitaminELabel = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminE_LabelEntryPrimarily)
        let vitaminE = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminE)
        let betaToco = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Beta)
        let gammaToco = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Gamma)
        let deltaToco = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Delta)
        let alphaTocotri = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Alpha)
        let betaTocotri = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Beta)
        let gammaTocotri = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Gamma)
        let deltaTocotri = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Delta)

        if let vitaminEAdded = vitaminEAdded {
            NutrientRow(vitaminEAdded)
        }
        if let vitaminETocopherol = vitaminETocopherol {
            NutrientRow(vitaminETocopherol)
        }
        if let vitaminELabel = vitaminELabel {
            NutrientRow(vitaminELabel)
        }
        if let vitaminE = vitaminE {
            NutrientRow(vitaminE)
        }
        if let betaToco = betaToco {
            NutrientRow(betaToco)
        }
        if let gammaToco = gammaToco {
            NutrientRow(gammaToco)
        }
        if let deltaToco = deltaToco {
            NutrientRow(deltaToco)
        }
        if let alphaTocotri = alphaTocotri {
            NutrientRow(alphaTocotri)
        }
        if let betaTocotri = betaTocotri {
            NutrientRow(betaTocotri)
        }
        if let gammaTocotri = gammaTocotri {
            NutrientRow(gammaTocotri)
        }
        if let deltaTocotri = deltaTocotri {
            NutrientRow(deltaTocotri)
        }
    }
    
    @ViewBuilder private func VitaminK(_ nutrients: inout [Nutrient]) -> some View {
        let vitaminKMena = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminK_Menaquinone_4)
        let vitaminKDihydro = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminK_Dihydrophylloquinone)
        let vitaminKPhyllo = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone)

        if let vitaminKMena = vitaminKMena {
            NutrientRow(vitaminKMena)
        }
        if let vitaminKDihydro = vitaminKDihydro {
            NutrientRow(vitaminKDihydro)
        }
        if let vitaminKPhyllo = vitaminKPhyllo {
            NutrientRow(vitaminKPhyllo)
        }
    }
    
    @ViewBuilder private func Minerals(_ nutrients: inout [Nutrient]) -> some View {
        let calcium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca)
        let chlorine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Chlorine_Cl)
        let iron = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Iron_Fe)
        let magnesium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg)
        let phosphorus = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P)
        let potassium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Potassium_K)
        let sulfur = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Sulfur_S)
        let zinc = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn)
        let chromium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr)
        let cobalt = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cobalt_Co)
        let copper = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Copper_Cu)
        let fluoride = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Fluoride_F)
        let iodine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Iodine_I)
        let manganese = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn)
        let molybdenum = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Molybdenum_Mo)
        let selenium = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Selenium_Se)
        let boron = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Boron_B)
        let nickel = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Nickel_Ni)

        if let calcium = calcium {
            NutrientRow(calcium)
        }
        if let chlorine = chlorine {
            NutrientRow(chlorine)
        }
        if let iron = iron {
            NutrientRow(iron)
        }
        if let magnesium = magnesium {
            NutrientRow(magnesium)
        }
        if let phosphorus = phosphorus {
            NutrientRow(phosphorus)
        }
        if let potassium = potassium {
            NutrientRow(potassium)
        }
        if let sulfur = sulfur {
            NutrientRow(sulfur)
        }
        if let zinc = zinc {
            NutrientRow(zinc)
        }
        if let chromium = chromium {
            NutrientRow(chromium)
        }
        if let cobalt = cobalt {
            NutrientRow(cobalt)
        }
        if let copper = copper {
            NutrientRow(copper)
        }
        if let fluoride = fluoride {
            NutrientRow(fluoride)
        }
        if let iodine = iodine {
            NutrientRow(iodine)
        }
        if let manganese = manganese {
            NutrientRow(manganese)
        }
        if let molybdenum = molybdenum {
            NutrientRow(molybdenum)
        }
        if let selenium = selenium {
            NutrientRow(selenium)
        }
        if let boron = boron {
            NutrientRow(boron)
        }
        if let nickel = nickel {
            NutrientRow(nickel)
        }
    }
    
    @ViewBuilder private func Folate(_ nutrients: inout [Nutrient]) -> some View {
        let folateDfe = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Folate_DFE)
        let folate = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Folate_Total)
        let folateFood = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Folate_Food)
        let methylTetrahydrofolate = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_MethylTetrahydrofolate)
        let folicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FolicAcid)
        let formylFolicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FormylFolicAcid)
        let formylTetraHydrofolicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_FormylTetrahyrdofolicAcid)

        if let folateDfe = folateDfe {
            NutrientRow(folateDfe)
        }
        if let folate = folate {
            NutrientRow(folate)
        }
        if let folateFood = folateFood {
            NutrientRow(folateFood)
        }
        if let methylTetrahydrofolate = methylTetrahydrofolate {
            NutrientRow(methylTetrahydrofolate)
        }
        if let folicAcid = folicAcid {
            NutrientRow(folicAcid)
        }
        if let formylFolicAcid = formylFolicAcid {
            NutrientRow(formylFolicAcid)
        }
        if let formylTetraHydrofolicAcid = formylTetraHydrofolicAcid {
            NutrientRow(formylTetraHydrofolicAcid)
        }
    }
    
    @ViewBuilder private func Choline(_ nutrients: inout [Nutrient]) -> some View {
        let choline = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_Total)
        let cholineFree = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_Free)
        let cholineGlycero = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_FromGlycerophosphocholine)
        let cholinePhospho = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphocholine)
        let cholinePhosphotidyl = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphotidylCholine)
        let cholineSphing = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Choline_FromSphingomyelin)

        if let choline = choline {
            NutrientRow(choline)
        }
        if let cholineFree = cholineFree {
            NutrientRow(cholineFree)
        }
        if let cholineGlycero = cholineGlycero {
            NutrientRow(cholineGlycero)
        }
        if let cholinePhospho = cholinePhospho {
            NutrientRow(cholinePhospho)
        }
        if let cholinePhosphotidyl = cholinePhosphotidyl {
            NutrientRow(cholinePhosphotidyl)
        }
        if let cholineSphing = cholineSphing {
            NutrientRow(cholineSphing)
        }
    }
    
    @ViewBuilder private func OtherVitamins(_ nutrients: inout [Nutrient]) -> some View {
        let lycopene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Lycopene)
        let cisLycopene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cis_Lycopene)
        let transLycopene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Trans_Lycopene)
        let luteinZeaxanthin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Lutein_Zeaxanthin)
        let lutein = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Lutein)
        let zeaxanthin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Zeaxanthin)
        let cisLuteinZeaXanthin = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cis_Lutein_Zeaxanthin)
        let betaine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Betaine)

        if let lycopene = lycopene {
            NutrientRow(lycopene)
        }
        if let cisLycopene = cisLycopene {
            NutrientRow(cisLycopene)
        }
        if let transLycopene = transLycopene {
            NutrientRow(transLycopene)
        }
        if let luteinZeaxanthin = luteinZeaxanthin {
            NutrientRow(luteinZeaxanthin)
        }
        if let lutein = lutein {
            NutrientRow(lutein)
        }
        if let zeaxanthin = zeaxanthin {
            NutrientRow(zeaxanthin)
        }
        if let cisLuteinZeaXanthin = cisLuteinZeaXanthin {
            NutrientRow(cisLuteinZeaXanthin)
        }
        if let betaine = betaine {
            NutrientRow(betaine)
        }
    }
    
    @ViewBuilder private func OtherVarious(_ nutrients: inout [Nutrient]) -> some View {
        let caffeine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Caffeine)
        let theobromine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Theobromine)
        let egcg = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Epigallocatechin3Gallate)
        let phytoene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Phytoene)
        let phytofluene = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Phytofluene)

        if let caffeine = caffeine {
            NutrientRow(caffeine)
        }
        if let theobromine = theobromine {
            NutrientRow(theobromine)
        }
        if let egcg = egcg {
            NutrientRow(egcg)
        }
        if let phytoene = phytoene {
            NutrientRow(phytoene)
        }
        if let phytofluene = phytofluene {
            NutrientRow(phytofluene)
        }
    }
    
    @ViewBuilder private func Phytosterols(_ nutrients: inout [Nutrient]) -> some View {
        let phytosterols = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Phytosterols)
        let phytosterolsOther = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_PhytosterolsOther)
        let stigmasterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Stigmasterol)
        let campesterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Campesterol)
        let brassicasterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Brassicasterol)
        let betaSitosterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Beta_Sitosterol)
        let campestanol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Campestanol)
        let betaSitostanol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Beta_Sitostanol)
        let delta5Avenasterol = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Delta5Avenasterol)

        if let phytosterols = phytosterols {
            NutrientRow(phytosterols)
        }
        if let phytosterolsOther = phytosterolsOther {
            NutrientRow(phytosterolsOther)
        }
        if let stigmasterol = stigmasterol {
            NutrientRow(stigmasterol)
        }
        if let campesterol = campesterol {
            NutrientRow(campesterol)
        }
        if let brassicasterol = brassicasterol {
            NutrientRow(brassicasterol)
        }
        if let betaSitosterol = betaSitosterol {
            NutrientRow(betaSitosterol)
        }
        if let campestanol = campestanol {
            NutrientRow(campestanol)
        }
        if let betaSitostanol = betaSitostanol {
            NutrientRow(betaSitostanol)
        }
        if let delta5Avenasterol = delta5Avenasterol {
            NutrientRow(delta5Avenasterol)
        }
    }
    
    @ViewBuilder private func OtherAcids(_ nutrients: inout [Nutrient]) -> some View {
        let aceticAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_AceticAcid)
        let citricAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_CitricAcid)
        let lacticAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_LacticAcid)
        let malicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_MalicAcid)

        if let aceticAcid = aceticAcid {
            NutrientRow(aceticAcid)
        }
        if let citricAcid = citricAcid {
            NutrientRow(citricAcid)
        }
        if let lacticAcid = lacticAcid {
            NutrientRow(lacticAcid)
        }
        if let malicAcid = malicAcid {
            NutrientRow(malicAcid)
        }
    }
    
    @ViewBuilder private func AminoAcids(_ nutrients: inout [Nutrient]) -> some View {
        let tryptophan = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tryptophan)
        let threonine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Threonine)
        let isoleucine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Isoleucine)
        let leucine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Leucine)
        let lysine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Lysine)
        let methionine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Methionine)
        let cystine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cystine)
        let phenylalanine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Phenylalanine)
        let tyrosine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Tyrosine)
        let valine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Valine)
        let arginine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Arginine)
        let histidine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Histidine)
        let alanine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Alanine)
        let apsarticAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_AsparticAcid)
        let glutemicAcid = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_GlutamicAcid)
        let glycine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Glycine)
        let proline = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Proline)
        let serine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Serine)
        let hydroxyproline = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Hydroxyproline)
        let cysteine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Cysteine)
        let glutamine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Glutamine)
        let taurine = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Taurine)

        if let tryptophan = tryptophan {
            NutrientRow(tryptophan)
        }
        if let threonine = threonine {
            NutrientRow(threonine)
        }
        if let isoleucine = isoleucine {
            NutrientRow(isoleucine)
        }
        if let leucine = leucine {
            NutrientRow(leucine)
        }
        if let lysine = lysine {
            NutrientRow(lysine)
        }
        if let methionine = methionine {
            NutrientRow(methionine)
        }
        if let cystine = cystine {
            NutrientRow(cystine)
        }
        if let phenylalanine = phenylalanine {
            NutrientRow(phenylalanine)
        }
        if let tyrosine = tyrosine {
            NutrientRow(tyrosine)
        }
        if let valine = valine {
            NutrientRow(valine)
        }
        if let arginine = arginine {
            NutrientRow(arginine)
        }
        if let histidine = histidine {
            NutrientRow(histidine)
        }
        if let alanine = alanine {
            NutrientRow(alanine)
        }
        if let apsarticAcid = apsarticAcid {
            NutrientRow(apsarticAcid)
        }
        if let glutemicAcid = glutemicAcid {
            NutrientRow(glutemicAcid)
        }
        if let glycine = glycine {
            NutrientRow(glycine)
        }
        if let proline = proline {
            NutrientRow(proline)
        }
        if let serine = serine {
            NutrientRow(serine)
        }
        if let hydroxyproline = hydroxyproline {
            NutrientRow(hydroxyproline)
        }
        if let cysteine = cysteine {
            NutrientRow(cysteine)
        }
        if let glutamine = glutamine {
            NutrientRow(glutamine)
        }
        if let taurine = taurine {
            NutrientRow(taurine)
        }
    }
    
    @ViewBuilder private func FattyAcids(_ nutrients: inout [Nutrient]) -> some View {
        let ala = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA)
        let epa = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA)
        let dpa = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_22_5_N_3_DPA)
        let dha = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA)

        if let ala = ala {
            NutrientRow(ala)
        }
        if let epa = epa {
            NutrientRow(epa)
        }
        if let dpa = dpa {
            NutrientRow(dpa)
        }
        if let dha = dha {
            NutrientRow(dha)
        }
    }
    
    @ViewBuilder private func OtherNutrients(_ nutrients: inout [Nutrient]) -> some View {
        let last = nutrients.last
        
        ForEach(nutrients) { nutrient in
            NutrientRow(nutrient, showDivider: nutrient.fdcNumber != last?.fdcNumber)
        }
    }
    
    @ViewBuilder private func NutrientRow(
        _ nutrient: Nutrient,
        indentLevel: Int = 0,
        isNameBold: Bool = false,
        showDivider: Bool = true
    ) -> some View {
        let rdi = rdiLibrary.getRdis(nutrient.fdcNumber)?.getRdi(user)
        let number = nutrient.amount.formatted(maxDigits: 3)

        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            HStack {
                Text(nutrient.name)
                    .font(.system(size: UIConsts.nutrientFontSize))
                    .bold(isNameBold)
                Text("\(number)\(nutrient.unitName.lowercased())")
                    .font(.system(size: UIConsts.nutrientFontSize))
                Spacer()

                if let rdi = rdi, rdi.recommendedAmount > 0 {
                    let nutrientUnit = WeightUnit.unitFrom(nutrient)
                    let recommendedAmount = rdi.unit.convertTo(nutrientUnit, rdi.recommendedAmount)
                    let percent = (nutrient.amount / recommendedAmount) * 100.0
                    
                    Text("\(Int(percent))%")
                        .font(.system(size: UIConsts.nutrientFontSize))
                        .bold()
                }
           }
            .padding(.horizontal, 0.1)
            .padding(.leading, CGFloat(indentLevel) * 16)
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
        
        if showDivider {
            NutritionFactsLine(UIConsts.lineWidth_Thin)
        }
    }
}

fileprivate extension View {
    func nutritionFactsRow() -> some View {
        self
            .padding(.leading, FoodDetailsView.UIConsts.outlineMargin)
            .padding(.trailing, FoodDetailsView.UIConsts.outlineMargin)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
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
    let _ = swinjectContainer.autoregister(LocalDatabase.self) {
        LocalDatabaseForScreenshots()
    }
    let _ = swinjectContainer.autoregister(FoodSaver.self) {
        ConsumedFoodSaver(
            localDatabase: swinjectContainer.resolve(LocalDatabase.self)!,
            analytics: MockConsumedFoodSaverAnalytics())
    }
    
    NavigationStack {
        FoodDetailsView(foodId: 1234, mode: .searchResult)
    }
}
