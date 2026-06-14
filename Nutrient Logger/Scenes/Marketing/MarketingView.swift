//
//  MarketingView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 12/23/25.
//

import SwiftUI
import StoreKit

struct MarketingView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @State private var showDiscountCodeDialog = false
    @State private var discountCode: String = ""
    @State private var discountProductId: String?
    @FocusState private var isDiscountCodeFieldFocused: Bool
    @State private var isCheckingDiscountCode = false
    
    private var displayProducts: [Product] {
        // Highest price first so the yearly plan (best value/LTV) is shown before monthly.
        subscriptionManager.products
            .map { $0.value }
            .sorted { $0.price > $1.price }
    }

    private var yearlySavingsPercent: Int? {
        guard let monthly = subscriptionManager.products[SubscriptionManager.monthlyProductId],
              let yearly = subscriptionManager.products[SubscriptionManager.yearlyProductId],
              monthly.price > 0 else {
            return nil
        }

        let annualCostIfMonthly = monthly.price * 12
        guard yearly.price < annualCostIfMonthly else { return nil }

        let savings = (annualCostIfMonthly - yearly.price) / annualCostIfMonthly
        return NSDecimalNumber(decimal: savings * 100).intValue
    }
    
    private func doPurchase(productId: String) {
        Task {
            isPurchasing = true
            do {
                let _ = try await subscriptionManager.purchase(productId: productId)
            } catch {
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
            }
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
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
            Text("Unlock Nutrient Logger Premium")
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }

        HStack {
            Text("Track every vitamin, mineral, and amino acid — completely offline. Your data never leaves your device.")
                .foregroundStyle(.secondary)
            Spacer()
        }

        VStack {
            MarketingPoint("Completely ad-free experience")
            MarketingPoint("Support an independent developer")
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
    
    @ViewBuilder private func SubscribeButton(product: Product) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if product.id == SubscriptionManager.yearlyProductId, let percent = yearlySavingsPercent {
                SavingsBadge(percent: percent)
            }

            Button {
                doPurchase(productId: product.id)
            } label: {
                HStack(spacing: 0) {
                    Text(product.displayName)
                        .font(.body.bold())
                        .multilineTextAlignment(.leading)
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
                .foregroundStyle(Color.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                .background {
                    RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                        .foregroundStyle(Color.accentColor.gradient)
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
        .foregroundColor(.blue)
        .offerCodeRedemption(isPresented: $showDiscountCodeDialog) { result in
            handleOfferCodeCompletion()
        }
        .padding(.top)
    }
    
    @ViewBuilder private func RestoreSubscriptionButton() -> some View {
        Button("Restore Subscription") {
            restorePurchases()
        }
        .foregroundColor(.blue)
        .padding(.top)
    }
}

#Preview {
    MarketingView()
        .environmentObject(SubscriptionManager())
}
