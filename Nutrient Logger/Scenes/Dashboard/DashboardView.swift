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

    private static let streakMilestones: Set<Int> = [3, 7, 14, 30, 60, 90, 180, 365]

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var dataController: DataController
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    @State private var showSearch: Bool = false

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var subscriptionAnalytics: SubscriptionAnalytics

    @State private var date: SimpleDate = .today
    @State private var showDatePicker: Bool = false
    @Query private var consumedFoods: [ConsumedFood]

    @AppStorage("loggingStreakCount") private var loggingStreakCount: Int = 0
    @AppStorage("loggingStreakLastLoggedDate") private var loggingStreakLastLoggedDateRaw: Int = 0
    @AppStorage("loggingStreakLongestCount") private var loggingStreakLongestCount: Int = 0
    @AppStorage("lastAutoMarketingPromptDate") private var lastAutoMarketingPromptDateRaw: Int = 0

    @State private var showAutoMarketingView: Bool = false
    @State private var showStreakStats: Bool = false
    @State private var showLaunchOfferPaywall: Bool = false
    @State private var now: Date = .now

    @AppStorage("onboardingStartedAt") private var onboardingStartedAt: Double = 0

    private var isInDiscountWindow: Bool {
        guard onboardingStartedAt > 0 else { return false }
        return Date.now.timeIntervalSince1970 - onboardingStartedAt < 24 * 3600
    }

    private var discountTimeRemaining: String {
        let seconds = max(0, 24 * 3600 - (now.timeIntervalSince1970 - onboardingStartedAt))
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var todaysFoods: [ConsumedFood] {
        consumedFoods.filter { $0.dateLogged == .today }
    }

    private var loggingStreakStartDate: SimpleDate? {
        guard loggingStreakCount > 0,
              let lastLogged = SimpleDate(rawValue: UInt32(loggingStreakLastLoggedDateRaw))
        else { return nil }
        return lastLogged.adding(days: -(loggingStreakCount - 1))
    }

    private var loggedFoodToday: Bool {
        !todaysFoods.isEmpty
    }

    private func updateLoggingStreak() {
        let store = LoggingStreakStore()
        let previousCount = loggingStreakCount
        let streak = store.load().updated(loggedToday: loggedFoodToday)

        loggingStreakCount = streak.count
        loggingStreakLastLoggedDateRaw = streak.lastLoggedDate.map { Int($0) } ?? 0

        store.save(streak)

        if streak.count > previousCount && Self.streakMilestones.contains(streak.count) {
            engagementAnalytics.streakMilestoneReached(days: streak.count)
        }
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
                if isInDiscountWindow && !subscriptionManager.isSubscribed {
                    LaunchDiscountBanner()
                        .padding(.horizontal)
                }
                StreakCardView(count: loggingStreakCount, unit: "Day", milestones: Self.streakMilestones, onTap: { showStreakStats = true })
                    .padding(.horizontal)
                DashboardNutrientSections(date: date, foods: foodItems, consumedFoods: todaysConsumedFoods, allConsumedFoods: consumedFoods)
            }
        }
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
        .task { await subscriptionManager.checkSubscriptionTransitions(analytics: subscriptionAnalytics) }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
        .fullScreenCover(isPresented: $showLaunchOfferPaywall) {
            MarketingView(trigger: .smartPaywall)
        }
        .onChange(of: todaysConsumedFoods, initial: true) { fetchFoods() }
        .onChange(of: todaysFoods, initial: true) { _, _ in onTodaysFoodsChanged() }
        .animation(.snappy, value: date)
        .animation(.snappy, value: todaysConsumedFoods)
        .animation(.snappy, value: foodItems)
        .navigationDestination(isPresented: $showSearch) {
            FoodSearchView(onFoodSaved: { foodItem, portion in
                try FoodSaver.forConsumedFoods(modelContext: modelContext).saveFoodItem(foodItem, portion)
                DispatchQueue.main.async {
                    dataController.updateDailySummary()
                }
            })
        }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showAutoMarketingView) {
            MarketingView(trigger: .smartPaywall)
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
        .sheet(isPresented: $showStreakStats) {
            StreakStatsView(
                title: "Daily Logging",
                count: loggingStreakCount,
                unit: "Day",
                longestCount: loggingStreakLongestCount,
                startDate: loggingStreakStartDate,
                milestones: Self.streakMilestones
            )
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            DateButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
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
            description: Text("You haven't logged anything yet today. Tap the search icon to find foods and add them to your log!")
        )
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func LaunchDiscountBanner() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch offer ends in \(discountTimeRemaining)")
                    .font(.subheadline.bold())
                Text("Upgrade at a discount before it expires")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Upgrade") {
                showLaunchOfferPaywall = true
            }
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .clipShape(Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    NavigationStack {
        DashboardView()
    }
    .environmentObject(AdProviderFactory.forDev)
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
