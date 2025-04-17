//
//  ConsumedNutrientDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/11/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Add colors
struct ConsumedNutrientDetailsView: View {
    
    private struct MealFoods: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let foods: [FoodItem]
    }
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Inject private var adProvider: AdProvider
    @Inject private var nutrientRdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService

    @State private var isExplanationLoaded: Bool = false
    @State private var showExplanation: Bool = false
    @State private var infoString: AttributedString = ""
    @State private var rdi: LifeStageNutrientRdi? = nil
    
    private let nutrient: Nutrient
    private let nutrientFoodPairs: [NutrientFoodPair]
    
    private var user: User { userService.currentUser }

    private var hasRdi: Bool { recommendedAmount != nil || upperLimit != nil }
    
    private var nutrientUnit: WeightUnit {
        WeightUnit.unitFrom(nutrientFoodPairs[0].nutrient)
    }
    
    private var unitName: String {
        nutrientFoodPairs[0].nutrient.unitName
    }
    
    private var amount: String {
        let currentAmount = nutrientFoodPairs.reduce(0.0) { $0 + $1.nutrient.amount }
        return "\(currentAmount.formatted(maxDigits: 2))\(unitName)"
    }
    
    private var recommendedAmount: String? {
        guard let rdi = rdi else { return nil }
        
        let amount = rdi.unit.convertTo(nutrientUnit, rdi.recommendedAmount)
        let recommendedAmountStr = amount.formatted(maxDigits: 2)
        return "\(recommendedAmountStr)\(unitName)"
    }
    
    private var upperLimit: String? {
        guard let rdi = rdi else { return nil }
        
        let amount = rdi.unit.convertTo(nutrientUnit, rdi.upperLimit)
        let upperLimitAmountStr = amount.formatted(maxDigits: 2)
        return "\(upperLimitAmountStr)\(unitName)"
    }
    
    private var mealFoods: [MealFoods] {
        var mealTimeFoodMap: [MealTime: [FoodItem]] = [:]
        
        nutrientFoodPairs
            .map { $0.food }
            .forEach { food in
                mealTimeFoodMap[food.mealTime ?? .none, default: []].append(food)
            }
        
        return mealTimeFoodMap
            .reduce(into: []) { result, element in
                result.append(MealFoods(mealTime: element.key, foods: element.value))
            }
    }
    
    private func loadExplanation() async {
        guard NutrientExplanationMaker.canMakeFor(nutrient.fdcNumber) else {
            isExplanationLoaded = false
            return
        }

        do {
            infoString = try await NutrientExplanationMaker.make(nutrient.fdcNumber)
            isExplanationLoaded = true
        } catch {
            print("Failed to load explanation for \(nutrient.name): \(error)")
        }
    }
    
    init(
        nutrient: Nutrient,
        nutrientFoodPairs: [NutrientFoodPair]
    ) {
        self.nutrient = nutrient
        self.nutrientFoodPairs = nutrientFoodPairs
        
        self.rdi = nutrientRdiLibrary.getRdis(nutrient.fdcNumber)?.getRdi(userService.currentUser)
    }
    
    var body: some View {
        List {
            AmountRow()
            RecommendedAmountRow()
            UpperLimitRow()
            Chart()
            FoodsSection()
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .task { await loadExplanation() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(nutrient.name)
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            InfoButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func InfoButton() -> some View {
        NavigationLink {
            NutrientInfoView(
                nutrientName: nutrient.name,
                infoString: infoString
            )
        } label: {
            Image(systemName: showExplanation ? "x.circle" : "info.circle")
        }
        .disabled(!isExplanationLoaded)
        .opacity(isExplanationLoaded ? 1 : 0)
        .animation(.snappy, value: isExplanationLoaded)
        .animation(.snappy, value: showExplanation)
    }
    
    @ViewBuilder private func AmountRow() -> some View {
        HStack {
            Text("Amount Consumed")
            Spacer()
            Text(amount)
                .bold()
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func RecommendedAmountRow() -> some View {
        if let recommendedAmount = recommendedAmount {
            HStack {
                Text("Recommended Amount")
                Spacer()
                Text(recommendedAmount)
                    .bold()
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func UpperLimitRow() -> some View {
        if let upperLimit = upperLimit {
            HStack {
                Text("Upper Limit")
                Spacer()
                Text(upperLimit)
                    .bold()
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func Chart() -> some View {
        let rdi = nutrientRdiLibrary.getRdis(nutrient.fdcNumber)?.getRdi(user)
        
        ConsumedNutrientChart(
            nutrientFoodPairs: nutrientFoodPairs,
            rdi: rdi,
            style: .cumulative
        )
        .frame(height: 250)
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FoodsSection() -> some View {
        Section {
            ForEach(mealFoods) { mealFoods in
                Text(mealFoods.mealTime.rawValue)
                    .listSubsectionHeader()
                ForEach(mealFoods.foods) { food in
                    ConsumedNutrientDetailsFoodRow(food: food)
                }
            }
        } header: {
            Text("Foods")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(AdProvider.self) {
        MockAdProvider()
    }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {
        UsdaNutrientRdiLibrary.create()
    }
    let _ = swinjectContainer.autoregister(UserService.self) {
        MockUserService(currentUser: .sample)
    }
    
    let nutrient: Nutrient = .init(
        fdcNumber: "301",
        name: "Calcium",
        unitName: "g"
    )
    
    let food: FoodItem = {
        var food = FoodItem(
            fdcId: 1097512,
            name: "Milk",
            fdcType: "survey",
            nutrientGroups: [
                .init(
                    fdcNumber: "300",
                    name: "Minerals",
                    nutrients: [nutrient]
                )
            ],
            gramWeight: 100,
        )
        food.mealTime = .breakfast
        
        food.portionName = "cup (236 ml)"
        food.amount = 1
        
        return food
    }()
    
    let nutrientFoodPairs: [NutrientFoodPair] = [
        .init(
            nutrient: nutrient,
            food: food
        )
    ]
    
    NavigationStack {
        ConsumedNutrientDetailsView(
            nutrient: nutrient,
            nutrientFoodPairs: nutrientFoodPairs
        )
    }
}
