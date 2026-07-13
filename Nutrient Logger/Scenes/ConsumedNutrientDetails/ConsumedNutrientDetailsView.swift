//
//  ConsumedNutrientDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/11/25.
//

import SwiftUI
import SwinjectAutoregistration

struct ConsumedNutrientDetailsView: View {
    
    private struct MealFoods: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let foods: [FoodItem]
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var nutrientRdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var premiumAnalytics: PremiumAnalytics

    @State private var showMarketingView: Bool = false
    @State private var isExplanationLoaded: Bool = false
    @State private var showExplanation: Bool = false
    @State private var infoString: AttributedString = ""
    @State private var rdi: LifeStageNutrientRdi? = nil
    
    private let nutrient: Nutrient
    private let nutrientFoodPairs: [NutrientFoodPair]
    
    private var colorPalette: ColorPalette {
        if nutrient.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat {
            return ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_Lipids)
        }
        if nutrient.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Protein {
            return ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_AminoAcids)
        }

        let num = FdcNutrientGroupMapper.groupNumberForNutrient(nutrient.fdcNumber)
        return ColorPaletteService.getColorPaletteFor(number: num)
    }
    
    private var user: User { userService.currentUser }

    private var hasRdi: Bool { recommendedAmount != nil || upperLimit != nil }
    
    private var nutrientUnit: WeightUnit {
        guard let first = nutrientFoodPairs.first else { return WeightUnit.unitFrom(nutrient) }
        return WeightUnit.unitFrom(first.nutrient)
    }
    
    private var unitName: String {
        guard !nutrientFoodPairs.isEmpty else { return nutrient.unitName }
        return nutrientFoodPairs[0].nutrient.unitName
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
                var foods = mealTimeFoodMap[food.mealTime ?? .none, default: []]
                // Guards against the same food being paired with this nutrient more than once
                // upstream from rendering as duplicate rows here.
                if !foods.contains(food) {
                    foods.append(food)
                }
                mealTimeFoodMap[food.mealTime ?? .none] = foods
            }

        return mealTimeFoodMap
            .reduce(into: []) { result, element in
                result.append(MealFoods(mealTime: element.key, foods: element.value))
            }
            .sorted { $0.mealTime < $1.mealTime }
    }
    
    private func loadExplanation() async {
        guard NutrientExplanationMaker.canMakeFor(nutrient.fdcNumber) else {
            isExplanationLoaded = false
            return
        }

        do {
            infoString = try await NutrientExplanationMaker.make(nutrient.fdcNumber, colorScheme: colorScheme)
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
        
        self.rdi = NutrientGoalDefaults.effectiveRdi(
            for: nutrient.fdcNumber,
            user: userService.currentUser,
            rdiLibrary: nutrientRdiLibrary
        )
    }
    
    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .small)
            AmountRow()
            RecommendedAmountRow()
            UpperLimitRow()
            Chart()
            TrendsSection()
            FoodsSection()
        }
        .listDefaultModifiers()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .task { await loadExplanation() }
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .trendCharts)
        }
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
        let rdi = NutrientGoalDefaults.effectiveRdi(
            for: nutrient.fdcNumber,
            user: user,
            rdiLibrary: nutrientRdiLibrary
        )

        ConsumedNutrientChart(
            nutrientFoodPairs: nutrientFoodPairs,
            rdi: rdi,
            style: .cumulative,
            accentColor: colorPalette.accent
        )
        .frame(height: 250)
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func TrendsSection() -> some View {
        Section {
            if subscriptionManager.isSubscribed {
                NavigationLink {
                    NutrientTrendView(
                        nutrient: nutrient,
                        colorPalette: colorPalette
                    )
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(colorPalette.accent)
                        Text("View Trends")
                        Spacer()
                        Text("7 & 30 Day")
                            .font(.caption)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
                }
                .listRowDefaultModifiers()
            } else {
                Button {
                    premiumAnalytics.premiumFeatureTapped(feature: "trend_charts")
                    showMarketingView = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.text.opacity(0.4))
                        Text("View Trends")
                        Spacer()
                        Text("Premium")
                            .font(.caption)
                            .foregroundStyle(colorPalette.accent)
                    }
                    .foregroundStyle(Color.text)
                }
                .listRowDefaultModifiers()
            }
        } header: {
            Text("Nutrient Trends")
        }
    }

    @ViewBuilder private func FoodsSection() -> some View {
        if !mealFoods.isEmpty {
            Section {
                ForEach(mealFoods) { mealFoods in
                    MealCard(mealFoods)
                }
            } header: {
                Text("Contributing Foods")
            }
        }
    }

    @ViewBuilder private func MealCard(_ mealFoods: MealFoods) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(mealFoods.mealTime.rawValue)
                .listSubsectionHeader()
                .padding(.bottom, 4)
            ForEach(Array(mealFoods.foods.enumerated()), id: \.offset) { index, food in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 4)
                }
                ConsumedNutrientDetailsFoodRow(
                    nutrientNumber: nutrient.fdcNumber,
                    food: food,
                    wrapInCard: false
                )
            }
        }
        .padding()
        .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {
        UsdaNutrientRdiLibrary.create()
    }
    let _ = swinjectContainer.autoregister(UserService.self) {
        MockUserService(currentUser: .sample)
    }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) {
        MockPremiumAnalytics()
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
    .environmentObject(AdProviderFactory.forDev)
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
