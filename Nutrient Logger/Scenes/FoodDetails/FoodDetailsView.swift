//
//  FoodDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

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
    
    @State private var food: FoodItem?
    @State private var portions: [Portion] = []
    @State private var selectedPortion: Portion?
    
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    
    let foodId: Int
    let mode: Mode
    
    private let localDatabase = swinjectContainer~>LocalDatabase.self
    private let remoteDatabase = swinjectContainer~>RemoteDatabase.self
    
    private let user = (swinjectContainer~>UserService.self).currentUser
    private let rdiLibrary = swinjectContainer~>NutrientRdiLibrary.self
    
    private func show(alert: String) {
        showAlert = true
        alertTitle = alert
    }
    
    private func fetchLoggedFoodAndPortions() {
        do {
            food = try localDatabase.getFood(foodId)
            portions = []
        } catch {
            food = nil
            portions = []
            print("Failed to fetch logged food with id \(foodId): \(error.localizedDescription)")
        }
    }
    
    private func fetchRemoteFoodAndPortions() {
        do {
            food = try remoteDatabase.getFood(String(foodId))
            if var food = food {
                portions = try remoteDatabase.getPortions(food)
                
                if let portion = selectedPortion {
                    print("applying portion \(portion.name)")
                    food = try food.applyingPortion(portion)
                    print("applied portion \(food.portionName)")
                    self.food = food
                }
            } else {
                portions = []
                selectedPortion = nil
                print("Failed to find remote food with id \(foodId)")
            }
        } catch {
            food = nil
            portions = []
            selectedPortion = nil
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
    
    private func apply(portion: Portion) {
        food = try? food?.applyingPortion(portion)
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
    
    init(foodId: Int, mode: Mode) {
        self.foodId = foodId
        self.mode = mode
    }
    
    var body: some View {
        var nutrients = displayNutrients
        
        List {
            NutritionFactsCap(isTop: true)
            NutritionFactsFoodName()
            NutritionFactsLine(UIConsts.lineWidth_Thin)
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
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listDefaultModifiers()
        .environment(\.defaultMinListRowHeight, 1)
        .toolbar { Toolbar() }
        .onChange(of: selectedPortion ?? Portion.defaultPortion) { fetchFoodAndPortions() }
        .onAppear { fetchFoodAndPortions() }
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
        NavigationLink {
            //TODO: Navigate somewhere real
            Text("Add food")
        } label: {
            Image(systemName: "plus")
        }
    }
    
    @ViewBuilder private func NutritionFactsCap(isTop: Bool) -> some View {
        Rectangle()
            .fill(Color.black)
            .frame(width: .infinity, height: 2)
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
                .frame(width: UIConsts.outlineWidth, height: .infinity)
            Spacer()
            Rectangle()
                .frame(width: .infinity, height: width)
            Spacer()
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsPortion() -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
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
                    PortionsMenu()
                }
            }
            .padding(.leading, 0.1)
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
        }
        .nutritionFactsRow()
    }
    
    //TODO: Make sure this changes nutrients and everything else correctly
    @ViewBuilder private func PortionsMenu() -> some View {
        if mode == .loggedFood {
            Text(portionValue)
                .font(.system(size: UIConsts.portionFontSize).bold())
        } else {
            SwiftUI.Menu {
                ForEach(portions, id: \.self) { portion in
                    Button(portion.name) {
                        selectedPortion = portion
                    }
                }
            } label: {
                Text(portionValue)
                    .font(.system(size: UIConsts.portionFontSize).bold())
            }
        }
    }
    
    @ViewBuilder private func Calories(_ nutrients: inout [Nutrient]) -> some View {
        let calories = removeNutrient(&nutrients, FdcNutrientGroupMapper.NutrientNumber_Energy_KCal)
        
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
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
                .frame(width: UIConsts.outlineWidth, height: .infinity)
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
                .frame(width: UIConsts.outlineWidth, height: .infinity)
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
            .padding(.leading, CGFloat(indentLevel) * UIConsts.margin)
            Rectangle()
                .frame(width: UIConsts.outlineWidth, height: .infinity)
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
