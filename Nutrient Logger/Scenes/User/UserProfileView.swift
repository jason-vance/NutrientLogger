//
//  UserProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import SwiftUI
import SwiftData
import StoreKit
import SwinjectAutoregistration

struct UserProfileView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var premiumAnalytics: PremiumAnalytics

    @StateObject private var reviewPrompter = ReviewPrompter()

    @State private var user: User?
    @State private var loadedUser: User?

    @State private var showMarketingView: Bool = false
    @State private var marketingTrigger: PaywallTrigger = .healthSync
    @State private var showManageSubscriptions: Bool = false

    @Query private var consumedFoods: [ConsumedFood]
    @Query private var weightEntries: [WeightEntry]
    @Query private var bodyFatEntries: [BodyFatEntry]

    @AppStorage(HealthKitManager.healthSyncEnabledKey)
    private var healthSyncEnabled = false

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue

    @AppStorage(NotificationSettings.dailyReminderEnabledKey)
    private var dailyReminderEnabled = NotificationSettings.defaultDailyReminderEnabled
    @AppStorage(NotificationSettings.dailyReminderHourKey)
    private var dailyReminderHour = NotificationSettings.defaultDailyReminderHour
    @AppStorage(NotificationSettings.dailyReminderMinuteKey)
    private var dailyReminderMinute = NotificationSettings.defaultDailyReminderMinute
    @AppStorage(NotificationSettings.streakWarningEnabledKey)
    private var streakWarningEnabled = NotificationSettings.defaultStreakWarningEnabled

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var preferredHeightUnit: HeightUnit {
        HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn
    }

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

    private func presentMarketingView(trigger: PaywallTrigger, feature: String) {
        premiumAnalytics.premiumFeatureTapped(feature: feature)
        marketingTrigger = trigger
        showMarketingView = true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 2 * .spacingDefault) {
                NativeAdListRow(ad: $ad, size: .small)
                ProfileCard()
                SubscriptionCard()
                AchievementsCard()
                NutritionGoalsCard()
                DataCard()
                BodyCard()
                NotificationsCard()
                AboutFooter()
                VersionLabel()
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitle("Profile")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: marketingTrigger)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }

    // MARK: - Profile Card

    private var ageGenderHeightSummary: String {
        var parts: [String] = []
        if let age = user?.getUserAge() {
            let years = Int(age / (365.25 * 24 * 3600))
            parts.append("\(years)")
        }
        if let gender = user?.gender, gender != .unknown {
            parts.append(gender.rawValue.capitalized)
        }
        if let cm = user?.heightCm {
            parts.append(preferredHeightUnit.formattedHeight(cm: cm))
        }
        return parts.isEmpty ? "Set up your profile" : parts.joined(separator: " · ")
    }

    @ViewBuilder private func ProfileCard() -> some View {
        HStack(spacing: .spacingDefault) {
            Image(user?.gender == .female ? "profile_female" : "profile_male")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(ageGenderHeightSummary)
                    .font(.headline)
                NavigationLink {
                    EditProfileView(user: $user)
                } label: {
                    HStack(spacing: 2) {
                        Text("Edit Profile")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                }
            }
            Spacer()
        }
        .padding()
        .inCard(backgroundColor: Color.gray)
    }

    // MARK: - Subscription Card

    @ViewBuilder private func SubscriptionCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subscriptionManager.isSubscribed ? (subscriptionManager.planDisplayName ?? "Premium") : "Free")
                    .font(.subheadline.bold())
                Spacer()
                if subscriptionManager.isSubscribed {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            HStack {
                if subscriptionManager.isSubscribed, let expirationDate = subscriptionManager.expirationDate {
                    Text("Renews: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Unlock premium features")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(subscriptionManager.isSubscribed ? "Manage" : "Upgrade") {
                    if subscriptionManager.isSubscribed {
                        showManageSubscriptions = true
                    } else {
                        presentMarketingView(trigger: .profileUpsell, feature: "profile_subscription_card")
                    }
                }
                .font(.caption.bold())
            }
        }
        .padding()
        .inCard(backgroundColor: .blue)
    }

    // MARK: - Achievements Card

    private var longestStreakCount: Int {
        LoggingStreakStore().load().longestCount
    }

    private var daysLoggedCount: Int {
        Set(consumedFoods.map(\.dateLogged)).count
    }

    private var foodsTrackedCount: Int {
        Set(consumedFoods.map(\.fdcId)).count
    }

    private var bodyLogsCount: Int {
        Set(weightEntries.map(\.date)).union(Set(bodyFatEntries.map(\.date))).count
    }

    @ViewBuilder private func AchievementsCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Achievements")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
                AchievementRow(icon: "flame.fill", iconColor: .orange, title: "Longest Streak", value: "\(longestStreakCount) days")
                Divider().padding(.horizontal)
                AchievementRow(icon: "calendar", iconColor: .blue, title: "Days Logged", value: "\(daysLoggedCount)")
                Divider().padding(.horizontal)
                AchievementRow(icon: "leaf.fill", iconColor: .green, title: "Unique Foods Tracked", value: "\(foodsTrackedCount)")
                Divider().padding(.horizontal)
                AchievementRow(icon: "scalemass.fill", iconColor: .purple, title: "Body Logs", value: "\(bodyLogsCount)")
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func AchievementRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Nutrition Goals Card

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

    @ViewBuilder private func NutritionGoalsCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Nutrition Goals")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
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
                Divider().padding(.horizontal)
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
                Divider().padding(.horizontal)
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
                Divider().padding(.horizontal)
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
                Divider().padding(.horizontal)
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
                    .foregroundStyle(Color.primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
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
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Data Card

    @ViewBuilder private func DataCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Data")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
                AppleHealthRow()
                if HealthKitManager.shared.isAvailable {
                    Divider().padding(.horizontal)
                }
                DataNavRow("Custom Foods Library") {
                    CustomFoodsLibraryView()
                }
                Divider().padding(.horizontal)
                DataNavRow("Saved Meals") {
                    UserMealsView()
                }
                Divider().padding(.horizontal)
                DataNavRow("Browse Nutrients") {
                    NutrientLibraryView()
                }
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func AppleHealthRow() -> some View {
        if HealthKitManager.shared.isAvailable {
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
            .padding(.horizontal)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                if !subscriptionManager.isSubscribed {
                    presentMarketingView(trigger: .healthSync, feature: "health_sync")
                }
            }
        }
    }

    @ViewBuilder private func DataNavRow<Destination: View>(
        _ title: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Body Card

    @ViewBuilder private func BodyCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Body")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Weight Unit")
                    Spacer()
                    Picker("Weight Unit", selection: $preferredUnitRaw) {
                        ForEach(BodyWeightUnit.allCases, id: \.rawValue) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                Divider().padding(.horizontal)
                HStack {
                    Text("Height Unit")
                    Spacer()
                    Picker("Height Unit", selection: $preferredHeightUnitRaw) {
                        ForEach(HeightUnit.allCases, id: \.rawValue) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
        }
    }

    // MARK: - Notifications Card

    @ViewBuilder private func NotificationsCard() -> some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Notifications")
                    .listSectionHeader()
                Spacer()
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Daily Logging Reminder")
                    Spacer()
                    Toggle("", isOn: $dailyReminderEnabled)
                        .labelsHidden()
                        .onChange(of: dailyReminderEnabled) { rescheduleNotifications() }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                if dailyReminderEnabled {
                    Divider().padding(.horizontal)
                    HStack {
                        Text("Reminder Time")
                        Spacer()
                        DatePicker("", selection: dailyReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                Divider().padding(.horizontal)
                HStack {
                    Text("Streak Warning")
                    Spacer()
                    Toggle("", isOn: $streakWarningEnabled)
                        .labelsHidden()
                        .onChange(of: streakWarningEnabled) { rescheduleNotifications() }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
        }
    }

    // MARK: - About / Legal Footer

    @ViewBuilder private func AboutFooter() -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                Text(".")
                NavigationLink("Terms of Use") { TermsOfUseView() }
            }
            HStack(spacing: 6) {
                Button("Rate on App Store") { requestReview() }
                Text(".")
                Button("Support") { reviewPrompter.leaveFeedback() }
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.top, .spacingDefault)
    }

    @ViewBuilder private func VersionLabel() -> some View {
        Text("Version \(AppInfo.versionString) (\(AppInfo.buildNumberString))")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.bottom, .spacingDefault)
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
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
