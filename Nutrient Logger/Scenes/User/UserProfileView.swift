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

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var userService: UserService
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var premiumAnalytics: PremiumAnalytics

    @StateObject private var reviewPrompter = ReviewPrompter()

    @State private var user: User?
    @State private var loadedUser: User?

    @State private var showMarketingView: Bool = false
    @State private var marketingTrigger: PaywallTrigger = .healthSync
    @State private var showManageSubscriptions: Bool = false

    #if DEBUG
    @State private var showDebugMenu: Bool = false
    #endif

    @Query private var consumedFoods: [ConsumedFood]
    @Query private var weightEntries: [WeightEntry]
    @Query private var bodyFatEntries: [BodyFatEntry]

    @AppStorage(HealthKitManager.healthSyncEnabledKey)
    private var healthSyncEnabled = false

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue
    @AppStorage("profileSetupComplete") private var profileSetupComplete: Bool = false

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
        profileSetupComplete = loaded.isProfileComplete
    }

    private func saveUser() {
        guard let user else { return }
        guard user != loadedUser else { return }
        loadedUser = user
        profileSetupComplete = user.isProfileComplete
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
                PremiumCTARow(trigger: .profileUpsell, size: .small)
                ProfileCard()
                SubscriptionCard()
                AchievementsCard()
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
        if user?.isProfileComplete == true {
            HStack(spacing: .spacingDefault) {
                Image(user?.gender == .female ? "profile_female" : "profile_male")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(Color.primary)
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
        } else {
            SetUpProfilePrompt()
        }
    }

    @ViewBuilder private func SetUpProfilePrompt() -> some View {
        NavigationLink {
            EditProfileView(user: $user)
        } label: {
            HStack(spacing: .spacingDefault) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set up your profile")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Personalize your nutrient targets in under a minute")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .inCard(backgroundColor: Color.gray)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
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
                Divider().padding(.horizontal)
                ExportDataRow()
            }
            .padding(.vertical, 4)
            .inCard(backgroundColor: Color.gray)
        }
    }

    @ViewBuilder private func ExportDataRow() -> some View {
        if subscriptionManager.isSubscribed {
            DataNavRow("Export Data (CSV)") {
                ExportDataView()
            }
        } else {
            Button {
                presentMarketingView(trigger: .csvExport, feature: "csv_export")
            } label: {
                HStack {
                    Text("Export Data (CSV)")
                    Text("PREMIUM")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().foregroundStyle(Color.accentColor.gradient)
                        }
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
                Text("Units")
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
                Text(".")
                NavigationLink("Data Sources") { DataSourcesView() }
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
            #if DEBUG
            .onLongPressGesture(minimumDuration: 1) {
                showDebugMenu = true
            }
            .confirmationDialog("Debug Menu", isPresented: $showDebugMenu, titleVisibility: .visible) {
                Button("Reset Streaks", role: .destructive) {
                    LoggingStreakStore().reset()
                    BodyMeasurementStreakStore().reset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Clears the daily logging streak and weekly body-measurement streak from both local storage and iCloud, so a reinstall won't bring them back.")
            }
            #endif
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
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}
