//
//  FirstDayRecapView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import SwiftUI
import StoreKit
import SwinjectAutoregistration

/// Shown once, after the user's first full day of logging. Names the nutrients their food was
/// shortest on, then offers the free trial while that's fresh. See `FirstDayRecap`.
struct FirstDayRecapView: View {

    let foods: [ConsumedFood]

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var subscriptionAnalytics: SubscriptionAnalytics

    @AppStorage(NutrientBalanceSettings.hiddenKey) private var balanceHiddenRaw: String = ""
    @AppStorage(NutrientBalanceSettings.customKey) private var balanceCustomRaw: String = ""

    @State private var recap: FirstDayRecap?
    @State private var trialText: String?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showAllPlans = false
    @State private var hasLoggedAction = false

    private var usedReferenceAge: Bool { userService.currentUser.birthdate == nil }

    /// The plan the main button buys: yearly, at the launch price while that's still running.
    private var offeredProduct: Product? {
        let id = subscriptionManager.isInDiscountWindow
            ? SubscriptionManager.yearlyDiscountedProductId
            : SubscriptionManager.yearlyProductId
        return subscriptionManager.products[id]
    }

    // MARK: - Work

    private func loadRecap() {
        let user = userService.currentUser.withReferenceAgeIfMissing
        let ratios = NutrientBalanceSettings.effectiveRatios(hiddenRaw: balanceHiddenRaw, customRaw: balanceCustomRaw)
        let foods = self.foods
        let rdiLibrary = self.rdiLibrary
        let remoteDatabase = self.remoteDatabase

        Task {
            let results = DashboardWeeklyNutrientWatchSection.computeWeeklyWatch(
                foods: foods,
                ratios: ratios,
                user: user,
                rdiLibrary: rdiLibrary,
                remoteDatabase: remoteDatabase
            )
            let recap = FirstDayRecap(
                lows: results.deficiencies.map {
                    FirstDayRecap.Gap(id: $0.id, name: $0.name, percentOfGoal: $0.percentage)
                },
                highCount: results.highNutrients.count,
                balanceCount: results.balances.count
            )
            self.recap = recap
            engagementAnalytics.firstDayRecapShown(
                lowCount: recap.shownGaps.count + recap.moreLowCount,
                unnamedCount: recap.unnamedCount,
                isSubscribed: subscriptionManager.isSubscribed,
                usedReferenceAge: usedReferenceAge
            )
        }
    }

    /// "Try 7 days free" only when the plan has a free trial and this Apple ID can still use it.
    private func loadTrialText() async {
        guard let subscription = offeredProduct?.subscription,
              let offer = subscription.introductoryOffer,
              offer.paymentMode == .freeTrial,
              await subscription.isEligibleForIntroOffer
        else {
            trialText = nil
            return
        }
        trialText = Self.trialLength(offer.period)
    }

    static func trialLength(_ period: Product.SubscriptionPeriod) -> String {
        let value = period.value
        switch period.unit {
        case .day: return "\(value) day\(value == 1 ? "" : "s")"
        case .week: return value == 1 ? "7 days" : "\(value) weeks"
        case .month: return "\(value) month\(value == 1 ? "" : "s")"
        case .year: return "\(value) year\(value == 1 ? "" : "s")"
        @unknown default: return "\(value) days"
        }
    }

    private func logAction(_ action: String) {
        guard !hasLoggedAction else { return }
        hasLoggedAction = true
        engagementAnalytics.firstDayRecapAction(action: action)
    }

    private func close(action: String) {
        logAction(action)
        dismiss()
    }

    private func purchase(_ product: Product) {
        Task {
            isPurchasing = true
            subscriptionAnalytics.subscriptionPurchaseStarted(productId: product.id)
            do {
                let result = try await subscriptionManager.purchase(productId: product.id)
                switch result {
                case .completed(let isTrial):
                    subscriptionAnalytics.subscriptionPurchaseCompleted(productId: product.id, isTrial: isTrial)
                    close(action: isTrial ? "trial_started" : "purchased")
                case .cancelled:
                    subscriptionAnalytics.subscriptionPurchaseCancelled(productId: product.id)
                }
            } catch {
                subscriptionAnalytics.subscriptionPurchaseFailed(productId: product.id, error: error)
                errorMessage = (error as? SubscriptionError)?.message ?? error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    if let recap {
                        RecapContent(recap)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 120)
                    }
                }
                BottomBar()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        close(action: subscriptionManager.isSubscribed ? "done" : "not_now")
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .overlay {
            if isPurchasing {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .fullScreenCover(isPresented: $showAllPlans) {
            MarketingView(trigger: .firstDayRecap)
        }
        .onAppear {
            loadRecap()
            if subscriptionManager.products.isEmpty { subscriptionManager.refreshProducts() }
        }
        .task(id: offeredProduct?.id) { await loadTrialText() }
        .onChange(of: subscriptionManager.isSubscribed) { _, isSubscribed in
            // Bought or restored from "See all plans". The main button's purchase closes itself.
            if isSubscribed && !isPurchasing { close(action: "purchased_all_plans") }
        }
        // Swiping the sheet down counts as "not now".
        .onDisappear { logAction(subscriptionManager.isSubscribed ? "done" : "not_now") }
    }

    @ViewBuilder private func RecapContent(_ recap: FirstDayRecap) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR FIRST FULL DAY")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                Text(recap.headline)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text(usedReferenceAge
                     ? "Compared with general adult targets. Add your age and sex in Profile to get your own."
                     : "Compared with your daily goals, based on everything you logged today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if recap.shownGaps.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Nice work. Keep logging to see how your week adds up.")
                        .font(.subheadline)
                }
                .padding()
                .inCard(backgroundColor: .green)
            } else {
                VStack(spacing: 14) {
                    ForEach(recap.shownGaps) { gap in
                        GapRow(gap)
                    }
                }
                .padding()
                .inCard(backgroundColor: .orange)
            }

            if let summary = recap.unnamedSummary {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: subscriptionManager.isSubscribed ? "list.bullet" : "lock.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20)
                    Text(subscriptionManager.isSubscribed
                         ? "Also \(summary). See them all on your Nutrition tab."
                         : "Also \(summary). Premium shows you which ones.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }

            if !subscriptionManager.isSubscribed {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Premium keeps watch every day")
                        .font(.headline)
                    FeatureRow(icon: "exclamationmark.triangle.fill", text: "Every low, high and out-of-balance nutrient, named")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "7- and 30-day trends, so one off day doesn't mislead you")
                    FeatureRow(icon: "target", text: "Your own goals and upper limits")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func GapRow(_ gap: FirstDayRecap.Gap) -> some View {
        let color: Color = gap.percentOfGoal < 0.25 ? .red : .orange
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(gap.name)
                    .font(.body.bold())
                Spacer()
                Text("\(Int((gap.percentOfGoal * 100).rounded()))% of goal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2))
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: max(6, geometry.size.width * min(1, gap.percentOfGoal)))
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder private func FeatureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private func BottomBar() -> some View {
        if subscriptionManager.isSubscribed {
            Button {
                close(action: "done")
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        } else {
            VStack(spacing: 10) {
                if let product = offeredProduct {
                    Button {
                        purchase(product)
                    } label: {
                        Text(trialText.map { "Try \($0) free" } ?? "Unlock Premium")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(isPurchasing)

                    Text(trialText != nil
                         ? "Then \(product.displayPrice)/year. Cancel anytime."
                         : "\(product.displayPrice)/year. Cancel anytime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .padding(.vertical, 8)
                }

                HStack {
                    Button("See all plans") {
                        logAction("all_plans")
                        showAllPlans = true
                    }
                    Image(systemName: "circle.fill")
                        .scaleEffect(0.25)
                    Button("Not now") {
                        close(action: "not_now")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Free user") {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    Color.clear.sheet(isPresented: .constant(true)) {
        FirstDayRecapView(foods: [.dashboardSample])
            .environmentObject(SubscriptionManager(isForScreenshots: false))
    }
}
