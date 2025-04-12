//
//  ConsumedNutrientDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/11/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Add explanation view
//TODO: MVP: Add some kind of chart
struct ConsumedNutrientDetailsView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    private let adProvider = swinjectContainer~>AdProvider.self
    private let nutrientRdiLibrary = swinjectContainer~>NutrientRdiLibrary.self
    private let userService = swinjectContainer~>UserService.self

    @State private var isExplanationLoaded: Bool = false
    @State private var showExplanation: Bool = false
    
    private let nutrient: Nutrient
    private let nutrientFoodPairs: [NutrientFoodPair]
    private let rdi: LifeStageNutrientRdi?

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
        }
        .listDefaultModifiers()
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
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
        Button {
            showExplanation.toggle()
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
    
    let food: FoodItem = .init(
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
        gramWeight: 100
    )
    
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
