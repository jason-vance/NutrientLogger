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
                    VStack(alignment: .leading, spacing: 8) {
                        if subscriptionManager.isInDiscountWindow {
                            Text(launchOfferPercent.map { "Launch Offer — \($0)% Off" } ?? "Launch Offer")
                                .font(.caption.bold())
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                        }
                        Text("Unlock Nutrient Logger Premium")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 12) {
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "7-day and 30-day nutrient trend charts")
                        FeatureRow(icon: "scalemass.fill", text: "Weight and body fat tracking with goals")
                        FeatureRow(icon: "heart.fill", text: "Apple Health sync for calories, macros, and weight")
                        FeatureRow(icon: "target", text: "Custom micronutrient goals")
                        FeatureRow(icon: "xmark.circle.fill", text: "Completely ad-free experience")
                    }

                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        if let percent = launchOfferPercent {
                            HStack {
                                Spacer()
                                DiscountBanner(percent: percent)
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(Array(displayProducts.enumerated()), id: \.element.id) { index, product in
                                ProductButton(product: product, isRecommended: index == 0)
                            }
                        }

                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Button(action: onComplete) {
                Text("Skip for Now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 48)
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
            subscriptionManager.refreshProducts()
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
        Text("\(percent)% off the regular price")
            .font(.caption.bold())
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(Capsule().foregroundStyle(Color.green.gradient))
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }

    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingPaywallView(onComplete: {})
            .environmentObject(SubscriptionManager(isForScreenshots: true))
    }
}
