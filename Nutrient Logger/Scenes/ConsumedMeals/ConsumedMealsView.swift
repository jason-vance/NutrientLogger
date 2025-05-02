//
//  ConsumedMealsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI
import SwiftData

//TODO: Add ads here
struct ConsumedMealsView: View {
    
    let date: SimpleDate
    
    @Query private var consumedFoods: [ConsumedFood]
    
    private var todaysConsumedFoods: [ConsumedFood] {
//        return FoodItem.sampleFoods
//            .map {
//                ConsumedFood(
//                    fdcId: $0.fdcId,
//                    name: $0.name,
//                    portionAmount: $0.amount,
//                    portionGramWeight: $0.gramWeight,
//                    portionName: $0.portionName,
//                    dateLogged: .today,
//                    mealTime: $0.mealTime!
//                )
//            }
        
        consumedFoods
            .filter { $0.dateLogged == date }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        List {
            if !todaysConsumedFoods.isEmpty {
                let meals = DashboardMealList.from(todaysConsumedFoods)
                    .sorted { $0.mealTime < $1.mealTime }
                
                ForEach(meals) { meal in
                    MealHeader(meal.name)
                    ForEach(meal.foods) { food in
                        FoodRow(food)
                    }
                }
            }
        }
        .listDefaultModifiers()
        .navigationTitle("\(date.formatted())'s Meals")
    }
    
    @ViewBuilder private func MealHeader(_ text: String) -> some View {
        Text(text)
            .listSubsectionHeader()
    }
    
    @ViewBuilder private func FoodRow(_ consumedFood: ConsumedFood) -> some View {
        NavigationLink {
            FoodDetailsView(
                mode: .loggedFood(food: consumedFood),
                onFoodSaved: { (foodItem: FoodItem, portion: Portion) in
                    consumedFood.portionAmount = portion.amount
                    consumedFood.portionGramWeight = portion.gramWeight
                    consumedFood.portionName = portion.name
                    consumedFood.dateLogged = foodItem.dateLogged ?? consumedFood.dateLogged
                    consumedFood.mealTime = foodItem.mealTime ?? consumedFood.mealTime
                }
            )
        } label: {
            ConsumedMealFoodRow(consumedFood: consumedFood)
        }
        .listRowDefaultModifiers()
    }
}

struct ConsumedMealFoodRow: View {
    
    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal
    static let carbsKey = FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference
    static let fatKey = FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat
    static let proteinKey = FdcNutrientGroupMapper.NutrientNumber_Protein
    
    let consumedFood: ConsumedFood
    @State private var foodItem: FoodItem?
    @State private var aggregator: NutrientDataAggregator?
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    private var caloriesString: String? {
        guard let aggregator else { return nil }
        
        let calsAmount = aggregator.nutrientsByNutrientNumber[Self.calsKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        return "\(calsAmount.formatted(maxDigits: 0)) cals"
    }
    
    private var portionString: String? {
        guard foodItem != nil else { return nil }
        return "\(consumedFood.portionAmount.formatted(maxDigits: 2)) \(consumedFood.portionName)"
    }
    
    private var weightString: String? {
        guard foodItem != nil else { return nil }
        return "\((consumedFood.portionAmount * consumedFood.portionGramWeight).formatted(maxDigits: 0))g"
    }
    
    func fetchFoodItem() async {
        guard foodItem == nil else { return }
        
        Task {
            do {
                if let foodItem = try remoteDatabase.getFood(String(consumedFood.fdcId))?
                    .applyingPortion(Portion(amount: consumedFood.portionAmount, gramWeight: consumedFood.portionGramWeight))
                {
                    let aggregator = NutrientDataAggregator([foodItem])
                    
                    self.foodItem = foodItem
                    self.aggregator = aggregator
                } else {
                    throw NSError(domain: "FoodItem was nil", code: 0, userInfo: nil)
                }
            } catch {
                print("Error fetching food item: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(consumedFood.name)
                    .font(.headline)
                Spacer()
            }
            QuickStats()
            CarbsFatProtein()
                .padding(.top, 8)
        }
        .foregroundStyle(Color.text)
        .padding()
        .inCard(backgroundColor: Color.gray)
        .task { await fetchFoodItem() }
    }
    
    @ViewBuilder private func QuickStats() -> some View {
        HStack(spacing: 4) {
            QuickStat(icon: "flame.fill", iconColor: .orange, text: caloriesString)
            QuickStat(icon: "fork.knife", iconColor: .teal, text: portionString)
            QuickStat(icon: "scalemass.fill", iconColor: .purple, text: weightString)
            Spacer()
        }
    }
    
    @ViewBuilder private func QuickStat(icon: String, iconColor: Color, text: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(text ?? "xxxxxx")
                .lineLimit(1)
                .contentTransition(.numericText())
                .redacted(reason: text == nil ? [.placeholder] : [])
        }
        .font(.footnote)
    }
    
    @ViewBuilder private func CarbsFatProtein() -> some View {
        let carbs = aggregator?
            .nutrientsByNutrientNumber[Self.carbsKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let fat = aggregator?
            .nutrientsByNutrientNumber[Self.fatKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let protein = aggregator?
            .nutrientsByNutrientNumber[Self.proteinKey]?
            .reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let totalMacroCals = (carbs * 4) + (fat * 9) + (protein * 4)

        HStack {
            Macro(
                name: "Carbs",
                amount: carbs,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: foodItem == nil ? .gray : .indigo
            )
            Macro(
                name: "Fat",
                amount: fat,
                calorieFactor: 9,
                totalMacroCals: totalMacroCals,
                color: foodItem == nil ? .gray : .red
            )
            Macro(
                name: "Protein",
                amount: protein,
                calorieFactor: 4,
                totalMacroCals: totalMacroCals,
                color: foodItem == nil ? .gray : .green
            )
        }
    }
    
    @ViewBuilder private func Macro(
        name: String,
        amount: Double,
        calorieFactor: Double,
        totalMacroCals: Double,
        color: Color
    ) -> some View {
        HStack {
            CircleChart(
                amount: amount * calorieFactor,
                total: totalMacroCals,
                config: .init(color: color)
            )
            VStack {
                HStack {
                    Text(name)
                        .font(.caption)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack {
                    Text("\(amount.formatted(maxDigits: 0))g")
                        .contentTransition(.numericText())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    let _ = swinjectContainer.autoregister(UserService.self) {MockUserService(currentUser: .sample, )}
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {UsdaNutrientRdiLibrary.create()}

    let modelContainer: ModelContainer = {
        let schema = Schema([
            ConsumedFood.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try modelContainer.erase()
            modelContainer.mainContext.insert(ConsumedFood.dashboardSample)
            return modelContainer
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    NavigationStack {
        ConsumedMealsView(date: .today)
    }
    .modelContainer(modelContainer)
    .environmentObject(AdProviderFactory.forDev)
}
