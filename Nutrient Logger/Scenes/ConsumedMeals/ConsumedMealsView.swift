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

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataController: DataController

    let date: SimpleDate
    /// When set, the list jumps to this meal's card on appear, so tapping a meal on the
    /// dashboard lands on that meal rather than at the top of the day.
    var scrollToMealTime: MealTime? = nil

    @Query private var consumedFoods: [ConsumedFood]

    @State private var mealPendingDelete: DashboardMealList.Meal? = nil
    @State private var foodBeingEdited: ConsumedFood? = nil
    @State private var mealAddingFoodTo: DashboardMealList.Meal? = nil

    private var todaysConsumedFoods: [ConsumedFood] {
        consumedFoods
            .filter { $0.dateLogged == date }
            .sorted { $0.name < $1.name }
    }

    private var meals: [DashboardMealList.Meal] {
        DashboardMealList.from(todaysConsumedFoods)
    }

    private func deleteMeal(_ meal: DashboardMealList.Meal) {
        for food in meal.foods {
            modelContext.delete(food)
        }
        dataController.updateDailySummary()
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(meals) { meal in
                    ConsumedMealCard(
                        meal: meal,
                        date: date,
                        onDeleteRequested: { mealPendingDelete = meal },
                        onFoodTapped: { foodBeingEdited = $0 },
                        onAddFoodTapped: { mealAddingFoodTo = meal }
                    )
                    .listRowDefaultModifiers()
                    .id(meal.mealTime)
                }
            }
            .listDefaultModifiers()
            .onAppear {
                guard let scrollToMealTime else { return }
                // The cards size themselves as their foods load, so scroll on the next runloop
                // pass to land on the right offset instead of a stale one.
                DispatchQueue.main.async {
                    proxy.scrollTo(scrollToMealTime, anchor: .top)
                }
            }
        }
        .navigationTitle("\(date.formatted())'s Meals")
        // These live on the List itself (not inside each row's view) so a single, stable
        // navigationDestination handles every meal card — attaching one per row/card is a known
        // SwiftUI pitfall that can misroute navigation when the list re-renders.
        .navigationDestination(item: $foodBeingEdited) { consumedFood in
            FoodDetailsView(
                mode: .loggedFood(food: consumedFood),
                onFoodSaved: { (foodItem: FoodItem, portion: Portion) in
                    consumedFood.portionAmount = portion.amount
                    consumedFood.portionGramWeight = portion.gramWeight
                    consumedFood.portionName = portion.name
                    consumedFood.dateLogged = foodItem.dateLogged ?? consumedFood.dateLogged
                    consumedFood.mealTime = foodItem.mealTime ?? consumedFood.mealTime

                    dataController.updateDailySummary()
                }
            )
        }
        .navigationDestination(item: $mealAddingFoodTo) { meal in
            FoodSearchView(
                initialDate: date,
                initialMealTime: meal.mealTime == .none ? nil : meal.mealTime,
                onFoodSaved: { foodItem, portion in
                    try FoodSaver.forConsumedFoods(modelContext: modelContext).saveFoodItem(foodItem, portion)
                    DispatchQueue.main.async {
                        dataController.updateDailySummary()
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete \(mealPendingDelete?.name ?? "Meal")?\n\nThis will remove all \(mealPendingDelete?.foods.count ?? 0) food(s) logged for this meal.",
            isPresented: Binding(
                get: { mealPendingDelete != nil },
                set: { if !$0 { mealPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                if let meal = mealPendingDelete {
                    deleteMeal(meal)
                    mealPendingDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                mealPendingDelete = nil
            }
        }
    }
}

private struct ConsumedMealCard: View {

    static let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal
    static let carbsKey = FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference
    static let fatKey = FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat
    static let proteinKey = FdcNutrientGroupMapper.NutrientNumber_Protein

    let meal: DashboardMealList.Meal
    let date: SimpleDate
    let onDeleteRequested: () -> Void
    let onFoodTapped: (ConsumedFood) -> Void
    let onAddFoodTapped: () -> Void

    @Inject private var remoteDatabase: RemoteDatabase

    @State private var foodItems: [FoodItem] = []

    private var aggregator: NutrientDataAggregator? {
        foodItems.isEmpty ? nil : NutrientDataAggregator(foodItems)
    }

    private func fetchFoodItems() async {
        guard foodItems.isEmpty, !meal.foods.isEmpty else { return }

        Task {
            foodItems = meal.foods.compactMap { consumedFood in
                do {
                    var food = try remoteDatabase.getFood(String(consumedFood.fdcId))
                    food = try food?.applyingPortion(consumedFood.portion)
                    return food
                } catch {
                    print("Failed to fetch food with id \(consumedFood.fdcId): \(error)")
                    return nil
                }
            }
        }
    }

    private func amount(for key: String) -> Double {
        aggregator?.nutrientsByNutrientNumber[key]?
            .reduce(into: 0.0) { $0 += $1.nutrient.amount } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MealHeader()
            if !meal.foods.isEmpty {
                QuickStats()
                CarbsFatProtein()
                    .padding(.top, 4)
                Divider()
                FoodsList()
            }
            Divider()
            AddFoodButton()
        }
        .padding()
        .foregroundStyle(Color.text)
        .inCard(backgroundColor: Color.gray)
        .task { await fetchFoodItems() }
    }

    @ViewBuilder private func MealHeader() -> some View {
        HStack {
            Text(meal.name)
                .font(.headline)
            Spacer()
            if !meal.foods.isEmpty {
                Button {
                    onDeleteRequested()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private func QuickStats() -> some View {
        HStack(spacing: 4) {
            QuickStat(
                icon: "flame.fill",
                iconColor: .orange,
                text: foodItems.isEmpty ? nil : "\(amount(for: Self.calsKey).formatted(maxDigits: 0)) cals"
            )
            QuickStat(
                icon: "fork.knife",
                iconColor: .teal,
                text: "\(meal.foods.count) food\(meal.foods.count == 1 ? "" : "s")"
            )
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
        let carbs = amount(for: Self.carbsKey)
        let fat = amount(for: Self.fatKey)
        let protein = amount(for: Self.proteinKey)
        let totalMacroCals = (carbs * 4) + (fat * 9) + (protein * 4)

        HStack {
            Macro(name: "Carbs", amount: carbs, calorieFactor: 4, totalMacroCals: totalMacroCals, color: foodItems.isEmpty ? .gray : .indigo)
            Macro(name: "Fat", amount: fat, calorieFactor: 9, totalMacroCals: totalMacroCals, color: foodItems.isEmpty ? .gray : .red)
            Macro(name: "Protein", amount: protein, calorieFactor: 4, totalMacroCals: totalMacroCals, color: foodItems.isEmpty ? .gray : .green)
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
                config: .init(size: 28, lineWidth: 5, color: color)
            )
            VStack {
                HStack {
                    Text(name)
                        .font(.caption2)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack {
                    Text("\(amount.formatted(maxDigits: 0))g")
                        .contentTransition(.numericText())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder private func FoodsList() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(meal.foods.enumerated()), id: \.element.id) { index, food in
                if index > 0 {
                    Divider()
                }
                FoodRow(food)
            }
        }
    }

    @ViewBuilder private func FoodRow(_ consumedFood: ConsumedFood) -> some View {
        Button {
            onFoodTapped(consumedFood)
        } label: {
            HStack {
                Text(consumedFood.name)
                    .font(.subheadline)
                Spacer()
                Text("\(consumedFood.portionAmount.formatted(maxDigits: 2)) \(consumedFood.portionName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(Color.text)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func AddFoodButton() -> some View {
        Button {
            onAddFoodTapped()
        } label: {
            HStack {
                Spacer()
                Image(systemName: "plus.circle")
                Text("Add Food")
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(Color.accentColor)
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
    .environmentObject(CustomFoodDatabase())
}
