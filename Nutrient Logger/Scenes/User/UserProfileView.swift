//
//  UserProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileView: View {

    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var premiumAnalytics: PremiumAnalytics

    @State private var user: User?
    @State private var loadedUser: User?

    @State private var showMarketingView: Bool = false

    @AppStorage(HealthKitManager.healthSyncEnabledKey)
    private var healthSyncEnabled = false

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue

    @AppStorage(NotificationSettings.dailyReminderEnabledKey)
    private var dailyReminderEnabled = NotificationSettings.defaultDailyReminderEnabled
    @AppStorage(NotificationSettings.dailyReminderHourKey)
    private var dailyReminderHour = NotificationSettings.defaultDailyReminderHour
    @AppStorage(NotificationSettings.dailyReminderMinuteKey)
    private var dailyReminderMinute = NotificationSettings.defaultDailyReminderMinute

    private var dailyReminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: dailyReminderHour,
                    minute: dailyReminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                dailyReminderHour = components.hour ?? NotificationSettings.defaultDailyReminderHour
                dailyReminderMinute = components.minute ?? NotificationSettings.defaultDailyReminderMinute
                rescheduleNotifications()
            }
        )
    }

    private func fetchUser() {
        let loaded = userService.currentUser
        self.loadedUser = loaded
        self.user = loaded
    }

    private func saveUser() {
        guard let user else { return }
        guard user != loadedUser else { return }
        loadedUser = user
        Task {
            do {
                try await userService.save(user: user)
            } catch {
                print("Failed to save user: \(error.localizedDescription)")
            }
        }
    }

    private func rescheduleNotifications() {
        NotificationCoordinator.reschedule(modelContext: modelContext)
    }

    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .small)
            ProfileSettingsSection()
            NutritionGoalsSection()
            NotificationSettingsSection()
            AppleHealthSection()
            WeightTrackingSection()
            UserMealsSection()
            NutrientLibrarySection()
            LegalSection()
        }
        .scrollDismissesKeyboard(.immediately)
        .listDefaultModifiers()
        .navigationBarTitle("User Profile")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .healthSync)
        }
    }

    @ViewBuilder private func ProfileSettingsSection() -> some View {
        Section(header: Text("Profile Settings")) {
            BirthdateField()
            GenderField()
        }
    }

    private func goalBinding(
        get: @escaping () -> Double?,
        set: @escaping (Double?) -> Void,
        goalName: String
    ) -> Binding<Double?> {
        Binding(
            get: get,
            set: { newValue in
                let hadGoal = get() != nil
                set(newValue)
                if !hadGoal && newValue != nil {
                    engagementAnalytics.goalSet(goalName: goalName)
                }
            }
        )
    }

    @ViewBuilder private func NutritionGoalsSection() -> some View {
        Section(header: Text("Nutrition Goals")) {
            GoalField(
                "Calories",
                value: goalBinding(
                    get: { user?.calorieGoal },
                    set: { user?.calorieGoal = $0 },
                    goalName: "calorie"
                ),
                unit: "kcal",
                defaultValue: NutrientGoalDefaults.defaultCalorieGoal(for: user ?? User())
            )
            GoalField(
                "Carbs",
                value: goalBinding(
                    get: { user?.carbsGoalGrams },
                    set: { user?.carbsGoalGrams = $0 },
                    goalName: "carbs"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultCarbsGoal(for: user ?? User())
            )
            GoalField(
                "Fat",
                value: goalBinding(
                    get: { user?.fatGoalGrams },
                    set: { user?.fatGoalGrams = $0 },
                    goalName: "fat"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultFatGoal(for: user ?? User())
            )
            GoalField(
                "Protein",
                value: goalBinding(
                    get: { user?.proteinGoalGrams },
                    set: { user?.proteinGoalGrams = $0 },
                    goalName: "protein"
                ),
                unit: "g",
                defaultValue: NutrientGoalDefaults.defaultProteinGoal(for: user ?? User())
            )
            NavigationLink {
                MicronutrientGoalsView()
            } label: {
                VStack {
                    HStack {
                        Text("Micronutrient Goals")
                        if !subscriptionManager.isSubscribed {
                            Text("PREMIUM")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule().foregroundStyle(Color.accentColor.gradient)
                                }
                        }
                        Spacer()
                    }
                    HStack {
                        Text("Set custom targets for vitamins and minerals")
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .listRowDefaultModifiers()
        }
    }

    @ViewBuilder private func GoalField(
        _ title: String,
        value: Binding<Double?>,
        unit: String,
        defaultValue: Double
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(
                "\(defaultValue.formatted(maxDigits: 0))\(unit)",
                text: Binding(
                    get: {
                        if let v = value.wrappedValue {
                            return "\(v.formatted(maxDigits: 0))"
                        }
                        return ""
                    },
                    set: { newValue in
                        if newValue.isEmpty {
                            value.wrappedValue = nil
                        } else if let d = Double(newValue) {
                            value.wrappedValue = d
                        }
                    }
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .frame(maxWidth: 100)
            Text(unit)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func NotificationSettingsSection() -> some View {
        Section(header: Text("Notifications")) {
            Toggle("Daily Logging Reminder", isOn: $dailyReminderEnabled)
                .onChange(of: dailyReminderEnabled) { rescheduleNotifications() }
                .listRowDefaultModifiers()
            if dailyReminderEnabled {
                DatePicker("Reminder Time", selection: dailyReminderTime, displayedComponents: .hourAndMinute)
                    .listRowDefaultModifiers()
            }
        }
    }
    
    @ViewBuilder private func AppleHealthSection() -> some View {
        if HealthKitManager.shared.isAvailable {
        Section(header: Text("Apple Health")) {
            HStack {
                Text("Sync with Health")
                if !subscriptionManager.isSubscribed {
                    Text("PREMIUM")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().foregroundStyle(Color.accentColor.gradient)
                        }
                }
                Spacer()
                if subscriptionManager.isSubscribed {
                    Toggle("", isOn: Binding(
                        get: { healthSyncEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let authorized = await HealthKitManager.shared.requestAuthorization()
                                    if authorized {
                                        healthSyncEnabled = true
                                        engagementAnalytics.healthSyncEnabled()
                                    }
                                }
                            } else {
                                healthSyncEnabled = false
                                engagementAnalytics.healthSyncDisabled()
                            }
                        }
                    ))
                    .labelsHidden()
                }
            }
            .listRowDefaultModifiers()
            .contentShape(Rectangle())
            .onTapGesture {
                if !subscriptionManager.isSubscribed {
                    premiumAnalytics.premiumFeatureTapped(feature: "health_sync")
                    showMarketingView = true
                }
            }
        }
        }
    }

    @ViewBuilder private func WeightTrackingSection() -> some View {
        Section(header: Text("Body")) {
            Picker("Weight Unit", selection: $preferredUnitRaw) {
                ForEach(BodyWeightUnit.allCases, id: \.rawValue) { unit in
                    Text(unit.label).tag(unit.rawValue)
                }
            }
            .listRowDefaultModifiers()
        }
    }

    @ViewBuilder private func BirthdateField() -> some View {
        HStack {
            Text("Birthdate")
            Spacer()
            Button {
                
            } label: {
                Text(user?.birthdate?.toDate()?.relativeDisplayString() ?? "Not Set")
                    .bold()
            }
            .overlay{
                DatePicker(
                    "",
                    selection: .init(
                        get: { user?.birthdate?.toDate() ?? .now },
                        set: { user?.birthdate = SimpleDate(date: $0)! }
                    ),
                    displayedComponents: [.date]
                )
                .blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func GenderField() -> some View {
        HStack {
            Text("Sex")
            Spacer()
            Menu {
                Button(Gender.male.rawValue) {
                    user?.gender = .male
                }
                Button(Gender.female.rawValue) {
                    user?.gender = .female
                }
            } label: {
                Text(user?.gender.rawValue ?? "Not Set")
                    .bold()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func UserMealsSection() -> some View {
        Section {
            NavigationLink {
                UserMealsView()
            } label: {
                VStack {
                    HStack {
                        Text("My Recipes/Meals")
                        Spacer()
                    }
                    HStack {
                        Text("Group several food items together for easy logging")
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func NutrientLibrarySection() -> some View {
        Section {
            NavigationLink {
                NutrientLibraryView()
            } label: {
                VStack {
                    HStack {
                        Text("Browse Nutrients")
                        Spacer()
                    }
                    HStack {
                        Text("Learn about each nutrient and what kinds of foods contain them")
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func LegalSection() -> some View {
        Section(header: Text("Legal")) {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                VStack {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                    }
                }
            }
            .listRowDefaultModifiers()
            NavigationLink {
                TermsOfUseView()
            } label: {
                VStack {
                    HStack {
                        Text("Terms of Use")
                        Spacer()
                    }
                }
            }
            .listRowDefaultModifiers()
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self){MockUserService(currentUser: .sample)}
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }

    NavigationStack {
        UserProfileView()
    }
    .environmentObject(AdProviderFactory.forDev)
}
