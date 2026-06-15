//
//  DashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

//TODO: Days with foods hang for a second while loading
struct DashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var remoteDatabase: RemoteDatabase

    @State private var date: SimpleDate = .today
    @State private var showDatePicker: Bool = false
    @Query private var consumedFoods: [ConsumedFood]

    @AppStorage("loggingStreakCount") private var loggingStreakCount: Int = 0
    @AppStorage("loggingStreakLastLoggedDate") private var loggingStreakLastLoggedDateRaw: Int = 0
    @AppStorage("lastAutoMarketingPromptDate") private var lastAutoMarketingPromptDateRaw: Int = 0

    @State private var showAutoMarketingView: Bool = false

    private var todaysFoods: [ConsumedFood] {
        consumedFoods.filter { $0.dateLogged == .today }
    }

    private var loggedFoodToday: Bool {
        !todaysFoods.isEmpty
    }

    private func updateLoggingStreak() {
        let store = LoggingStreakStore()
        let streak = store.load().updated(loggedToday: loggedFoodToday)

        loggingStreakCount = streak.count
        loggingStreakLastLoggedDateRaw = streak.lastLoggedDate.map { Int($0) } ?? 0

        store.save(streak)
    }

    private func checkAutoMarketingPrompt() {
        let isFullDay = FullLoggingDay.isComplete(todaysFoods, on: .today)
        let lastShown = SimpleDate(rawValue: UInt32(lastAutoMarketingPromptDateRaw))

        if AutoMarketingPromptTrigger.shouldShow(
            isFullLoggingDay: isFullDay,
            isSubscribed: subscriptionManager.isSubscribed,
            lastShownDate: lastShown
        ) {
            lastAutoMarketingPromptDateRaw = Int(SimpleDate.today)
            showAutoMarketingView = true
        }
    }

    private func onTodaysFoodsChanged() {
        updateLoggingStreak()
        checkAutoMarketingPrompt()
        NotificationCoordinator.reschedule(modelContext: modelContext)
    }

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
    
    @State private var foodItems: [FoodItem] = []
    @State private var aggregator: NutrientDataAggregator?

    private func fetchFoods() {
//        foodItems = FoodItem.sampleFoods
//        return;
        
        Task {
            foodItems = todaysConsumedFoods
                .compactMap { consumedFood in
                    do {
                        var food = try remoteDatabase.getFood(String(consumedFood.fdcId))
                        food = try food?.applyingPortion(consumedFood.portion)
                        food?.dateLogged = consumedFood.dateLogged
                        food?.mealTime = consumedFood.mealTime
                        return food
                    } catch {
                        print("Failed to fetch food with id \(consumedFood.fdcId): \(error)")
                    }
                    return nil
                }
            aggregator = NutrientDataAggregator(foodItems)
        }
    }
    
    var navigationTitle: String {
        let date = Date.now
        
        let hour = Calendar.current.component(.hour, from: date)
        
        if hour >= 0 && hour < 2 {
            return "Try Sleep?"
        } else if hour >= 2 && hour < 12 {
            return "Good Morning"
        } else if hour >= 12 && hour < 17 {
            return "Good Afternoon"
        } else if hour >= 17 && hour < 22 {
            return "Good Evening"
        } else {
            return "Up Late?"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                NativeAdListRow(ad: $ad, size: .small)
                    .padding(.horizontal)
                DashboardNutrientSections(date: date, foods: foodItems)
                WhatIAteSection()
            }
        }
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .onChange(of: todaysConsumedFoods, initial: true) { fetchFoods() }
        .onChange(of: todaysFoods, initial: true) { _, _ in onTodaysFoodsChanged() }
        .animation(.snappy, value: date)
        .animation(.snappy, value: todaysConsumedFoods)
        .animation(.snappy, value: foodItems)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showAutoMarketingView) {
            MarketingView()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker(
                "Date",
                selection: .init(
                    get: { date.toDate() ?? .now },
                    set: { date = SimpleDate(date: $0)! }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DateButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            StreakBadge()
        }
    }

    @ViewBuilder private func StreakBadge() -> some View {
        if loggingStreakCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(loggingStreakCount)")
                    .font(.subheadline.bold())
                    .contentTransition(.numericText())
            }
        }
    }
    
    @ViewBuilder private func DateButton() -> some View {
        HStack {
            DecrementDateButton()
            Button {
                showDatePicker = true
            } label: {
                Text(date.formatted())
                    .frame(minWidth: 120)
            }
            IncrementDateButton()
        }
        .bold()
    }
    
    @ViewBuilder private func DecrementDateButton() -> some View {
        Button {
            date = date.adding(days: -1)
        } label: {
            Image(systemName: "chevron.backward")
        }
    }
    
    @ViewBuilder private func IncrementDateButton() -> some View {
        Button {
            date = date.adding(days: 1)
        } label: {
            Image(systemName: "chevron.forward")
        }
    }
    
    @ViewBuilder private func LoggingInstructions() -> some View {
        ContentUnavailableView(
            "Feeling Hungry?",
            systemImage: "face.smiling.inverse",
            description: Text("You haven't logged anything yet today. Go to the search tab to find foods and add them to your log!")
        )
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func WhatIAteSection() -> some View {
        let meals = DashboardMealList.from(todaysConsumedFoods)
            .sorted { $0.mealTime < $1.mealTime }
        
        if !meals.isEmpty {
            VStack(spacing: .spacingDefault) {
                HStack {
                    Text("Meals")
                        .listSectionHeader()
                    Spacer()
                }
                .padding(.top)
                LazyVStack(spacing: .spacingDefault) {
                    ForEach(meals) { meal in
                        DashboardMealRow(meal: meal, date: date)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        DashboardView()
    }
    .environmentObject(AdProviderFactory.forDev)
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
