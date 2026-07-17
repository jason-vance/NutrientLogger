//
//  MarketingView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 12/23/25.
//

import SwiftUI
import StoreKit
import SwinjectAutoregistration

struct MarketingView: View {

    let trigger: PaywallTrigger

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var subscriptionAnalytics: SubscriptionAnalytics

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    @State private var showDiscountCodeDialog = false
    @State private var discountCode: String = ""
    @State private var discountProductId: String?
    @FocusState private var isDiscountCodeFieldFocused: Bool
    @State private var isCheckingDiscountCode = false
    
    private var displayProducts: [Product] {
        let ids = subscriptionManager.isInDiscountWindow
            ? [SubscriptionManager.yearlyDiscountedProductId, SubscriptionManager.monthlyDiscountedProductId]
            : [SubscriptionManager.yearlyProductId, SubscriptionManager.monthlyProductId]
        return ids.compactMap { subscriptionManager.products[$0] }
    }

    // Reframes the ask around what the user is missing out on, matching the "Don't break your
    // streak!" loss-aversion framing already used by the streak-at-risk notification, rather than
    // a purely gain-framed pitch. Only applies to triggers tied to one specific locked feature —
    // generic entry points (smart paywall, deep link, profile upsell) keep the neutral headline.
    private var contextualLossHeadline: String? {
        switch trigger {
        case .trendCharts:
            return "Don't miss out on your 7 & 30-day nutrient trends"
        case .healthSync:
            return "Don't miss out on automatic Apple Health sync"
        case .weightGoal:
            return "Don't miss out on weight & body fat goal tracking"
        case .micronutrientGoals:
            return "Don't miss out on custom micronutrient goals"
        case .csvExport:
            return "Don't miss out on exporting your data to CSV"
        case .weeklyNutrientWatch:
            return "Don't miss out on this week's low & high nutrient alerts"
        case .smartPaywall, .deepLink, .removeAds, .profileUpsell:
            return nil
        }
    }

    private var yearlySavingsPercent: Int? {
        let monthlyId = subscriptionManager.isInDiscountWindow
            ? SubscriptionManager.monthlyDiscountedProductId
            : SubscriptionManager.monthlyProductId
        let yearlyId = subscriptionManager.isInDiscountWindow
            ? SubscriptionManager.yearlyDiscountedProductId
            : SubscriptionManager.yearlyProductId

        guard let monthly = subscriptionManager.products[monthlyId],
              let yearly = subscriptionManager.products[yearlyId],
              monthly.price > 0 else {
            return nil
        }

        let annualCostIfMonthly = monthly.price * 12
        guard yearly.price < annualCostIfMonthly else { return nil }

        let savings = (annualCostIfMonthly - yearly.price) / annualCostIfMonthly
        return Int(NSDecimalNumber(decimal: savings * 100).doubleValue)
    }
    
    private func doPurchase(productId: String) {
        Task {
            isPurchasing = true
            subscriptionAnalytics.subscriptionPurchaseStarted(productId: productId)
            do {
                let result = try await subscriptionManager.purchase(productId: productId)
                switch result {
                case .completed(let isTrial):
                    subscriptionAnalytics.subscriptionPurchaseCompleted(productId: productId, isTrial: isTrial)
                case .cancelled:
                    subscriptionAnalytics.subscriptionPurchaseCancelled(productId: productId)
                }
            } catch {
                subscriptionAnalytics.subscriptionPurchaseFailed(productId: productId, error: error)
                if let subError = error as? SubscriptionError {
                    errorMessage = subError.message
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
            isPurchasing = false
        }
    }
    
    private func handleOfferCodeCompletion() {
        Task {
            isPurchasing = true
            let _ = await subscriptionManager.isSubscribed()
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                let _ = await subscriptionManager.isSubscribed()
                subscriptionAnalytics.subscriptionRestored()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Spacer()
                    MarketingContentView()
                    Spacer()
                    
                    if subscriptionManager.isLoading {
                        LoadingView()
                    }

                    Text("Made by a solo developer, not a big company.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ForEach(displayProducts, id: \.self) { product in
                        SubscribeButton(product: product)
                    }
                    DiscountCodeButton()
                    RestoreSubscriptionButton()
                }
                .padding()
            }
            .toolbar { Toolbar() }
            .alert("Purchase Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
            .overlay { IsPurchasingView() }
            .onChange(of: subscriptionManager.isSubscribed, initial: true) { _, isSubscribed in
                if isSubscribed { dismiss() }
            }
            .onAppear {
                subscriptionManager.refreshProducts()
                subscriptionAnalytics.paywallShown(trigger: trigger)
            }
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                subscriptionAnalytics.paywallDismissed(trigger: trigger)
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    @ViewBuilder private func LoadingView() -> some View {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.accentColor)
                    .controlSize(.regular)
                    .padding()
                Spacer()
            }
    }
    
    @ViewBuilder private func IsPurchasingView() -> some View {
        if isPurchasing {
            ProgressView()
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
        }
    }
    
    @ViewBuilder private func MarketingContentView() -> some View {
        Image("MarketingImage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 0)
            .padding(.bottom, 16)

        HStack {
            Text(contextualLossHeadline ?? "Unlock Nutrient Logger Premium")
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }

        HStack {
            Text(
                contextualLossHeadline == nil
                    ? "Track every vitamin, mineral, and amino acid. Completely offline! Your data never leaves your device."
                    : "Track every vitamin, mineral, and amino acid. Completely offline! Unlock Premium to get this and everything else Nutrient Logger offers."
            )
                .foregroundStyle(.secondary)
            Spacer()
        }

        VStack {
            MarketingPoint("7-day and 30-day nutrient trend charts")
            MarketingPoint("Weight and body fat tracking with goals")
            MarketingPoint("Apple Health sync for calories, macros, and weight")
            MarketingPoint("Custom micronutrient goals")
            MarketingPoint("Export your data to CSV")
            MarketingPoint("Completely ad-free experience")
            MarketingPoint("Priority email support")
        }
        .padding(.top, 8)

        HStack {
            Spacer()
            Text("Your first 7 days are free. Cancel anytime.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder private func MarketingPoint(_ text: String) -> some View {
        HStack(alignment:.top) {
            ZStack {
                Image(systemName: "circle")
                    .foregroundStyle(Color.accentColor)
                    .font(.body)
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.blue)
                    .font(.caption2.bold())
            }
            Text(text)
                .font(.callout)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
    
    // Only meaningful for the yearly product — gives it a directly-comparable per-month figure
    // to sit next to monthly's sticker price, the same contrast trick as "$90 steak next to a
    // $40 salmon": the yearly lump sum alone doesn't read as cheap, its monthly-equivalent does.
    private func monthlyEquivalentPrice(for product: Product) -> String? {
        guard product.subscription?.subscriptionPeriod.unit == .year else { return nil }
        return (product.price / 12).formatted(product.priceFormatStyle)
    }

    @ViewBuilder private func SubscribeButton(product: Product) -> some View {
        let isYearly = product.id == SubscriptionManager.yearlyProductId || product.id == SubscriptionManager.yearlyDiscountedProductId

        VStack(alignment: .trailing, spacing: 4) {
            if isYearly, let percent = yearlySavingsPercent {
                SavingsBadge(percent: percent)
            }

            Button {
                doPurchase(productId: product.id)
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayName)
                            .font(.body.bold())
                            .multilineTextAlignment(.leading)
                        if isYearly, let monthlyEquivalent = monthlyEquivalentPrice(for: product) {
                            Text("Just \(monthlyEquivalent)/mo")
                                .font(.caption2)
                                .opacity(0.85)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(product.displayPrice)
                            .font(.body.bold())
                        if let period = product.subscription?.subscriptionPeriod.unit.localizedDescription {
                            Text("/\(period.lowercased())")
                                .font(.footnote)
                        }
                    }
                }
                .foregroundStyle(isYearly ? Color.white : Color.accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .background {
                    if isYearly {
                        Capsule().foregroundStyle(Color.accentColor.gradient)
                    } else {
                        Capsule().strokeBorder(Color.accentColor, lineWidth: 1.5)
                    }
                }
            }
            .disabled(isPurchasing)
        }
        .padding(.top, 8)
    }

    @ViewBuilder private func SavingsBadge(percent: Int) -> some View {
        Text("Save \(percent)% vs. Monthly")
            .font(.caption.bold())
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Capsule().foregroundStyle(Color.green.gradient))
    }
    
    @ViewBuilder private func DiscountCodeButton() -> some View {
        Button("Enter Discount Code") {
            showDiscountCodeDialog = true
            discountCode = ""
        }
        .foregroundColor(.accentColor)
        .offerCodeRedemption(isPresented: $showDiscountCodeDialog) { result in
            handleOfferCodeCompletion()
        }
        .padding(.top)
    }

    @ViewBuilder private func RestoreSubscriptionButton() -> some View {
        Button("Restore Subscription") {
            restorePurchases()
        }
        .foregroundColor(.accentColor)
        .padding(.top)
    }
}

#Preview("In Discount Window") {
    let _ = UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: "onboardingStartedAt")
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    MarketingView(trigger: .smartPaywall)
        .environmentObject(SubscriptionManager())
}

#Preview("Out of Discount Window") {
    let _ = UserDefaults.standard.set(0.0, forKey: "onboardingStartedAt")
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    MarketingView(trigger: .smartPaywall)
        .environmentObject(SubscriptionManager())
}
