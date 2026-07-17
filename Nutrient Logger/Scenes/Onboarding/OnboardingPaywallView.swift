//
//  OnboardingPaywallView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI
import StoreKit
import SwinjectAutoregistration

struct OnboardingPaywallView: View {

    let onComplete: () -> Void

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var subscriptionAnalytics: SubscriptionAnalytics

    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var displayProducts: [Product] {
        let ids = subscriptionManager.isInDiscountWindow
            ? [SubscriptionManager.yearlyDiscountedProductId, SubscriptionManager.monthlyDiscountedProductId]
            : [SubscriptionManager.yearlyProductId, SubscriptionManager.monthlyProductId]
        return ids.compactMap { subscriptionManager.products[$0] }
    }

    private func fullPriceProductId(for discountedProductId: String) -> String? {
        switch discountedProductId {
        case SubscriptionManager.monthlyDiscountedProductId: return SubscriptionManager.monthlyProductId
        case SubscriptionManager.yearlyDiscountedProductId: return SubscriptionManager.yearlyProductId
        default: return nil
        }
    }

    private func discountPercent(for product: Product) -> Int? {
        guard subscriptionManager.isInDiscountWindow,
              let fullPriceId = fullPriceProductId(for: product.id),
              let fullPriceProduct = subscriptionManager.products[fullPriceId],
              fullPriceProduct.price > product.price else {
            return nil
        }
        let savings = (fullPriceProduct.price - product.price) / fullPriceProduct.price
        return Int(NSDecimalNumber(decimal: savings * 100).doubleValue)
    }

    private var launchOfferPercent: Int? {
        displayProducts.first.flatMap(discountPercent)
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
                    onComplete()
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

    private func restorePurchases() {
        Task {
            isPurchasing = true
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.isSubscribed { onComplete() }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("\u{201C}I'm so glad you're here! My name is Jason, and I built Nutrient Logger to finally get a handle on my own health and nutrition. It's changed how I eat, and I can't wait for it to do the same for you. Thank you for giving it a try!\u{201D}")
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Image("me")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }

                        Text("Start your 7 day free trial now to get the most out of Nutrient Logger. Cancel anytime.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Spot nutrient gaps early with 7- & 30-day trends")
                        FeatureRow(icon: "scalemass.fill", text: "Reach your goals with weight & body fat tracking")
                        FeatureRow(icon: "heart.fill", text: "Save time with automatic Apple Health sync")
                        FeatureRow(icon: "target", text: "Tailor your diet with custom micronutrient goals")
                        FeatureRow(icon: "xmark.circle.fill", text: "Stay focused with zero ads, ever")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            
            VStack {
                if subscriptionManager.isLoading {
                    ProgressView()
                        .tint(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 8) {
                        if let percent = launchOfferPercent {
                            DiscountBanner(percent: percent)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(Array(displayProducts.enumerated()), id: \.element.id) { index, product in
                                ProductButton(product: product, isRecommended: index == 0)
                            }
                        }
                    }
                    
                    HStack {
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                        }
                        Image(systemName: "circle.fill")
                            .scaleEffect(0.25)
                        Button(action: onComplete) {
                            Text("Skip for Now")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .overlay {
            if isPurchasing {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }
        }
        .alert("Purchase Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .onAppear {
            // Products are loaded once at app launch (SubscriptionManager.init). Re-refreshing here
            // flips `isLoading` mid slide-in, which pops the product bar on top of the outgoing
            // screen during the transition — only refresh if the initial load hasn't landed yet.
            if displayProducts.isEmpty {
                subscriptionManager.refreshProducts()
            }
            subscriptionAnalytics.paywallShown(trigger: .smartPaywall)
        }
    }

    @ViewBuilder private func FeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.85))
            Spacer()
        }
    }

    @ViewBuilder private func ProductButton(product: Product, isRecommended: Bool) -> some View {
        Button(action: { purchase(product) }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(product.displayPrice + (product.subscription?.subscriptionPeriod.unit == .month ? "/mo" : "/yr"))
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(isRecommended ? 0.9 : 0.6))
                }
                Spacer()
                if isRecommended {
                    Text("Best Value")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isRecommended ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isRecommended ? Color.accentColor : Color.primary.opacity(0.15), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func DiscountBanner(percent: Int) -> some View {
        VStack {
            Text("Launch Offer")
                .font(.callout.bold())
            Text("\(percent)% off the regular price")
                .font(.caption.bold())
        }
        .foregroundStyle(Color.accent)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Capsule().foregroundStyle(Color.accent.gradient.opacity(0.15)))
    }
}

#Preview("In Discount Window") {
    let _ = UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: "onboardingStartedAt")
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    ZStack {
        OnboardingPaywallView(onComplete: {})
            .environmentObject(SubscriptionManager(isForScreenshots: true))
    }
}

#Preview("Out of Discount Window") {
    let _ = UserDefaults.standard.set(0.0, forKey: "onboardingStartedAt")
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    ZStack {
        OnboardingPaywallView(onComplete: {})
            .environmentObject(SubscriptionManager(isForScreenshots: true))
    }
}
