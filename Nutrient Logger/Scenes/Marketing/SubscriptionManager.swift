//
//  SubscriptionManager.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 12/23/25.
//

import Foundation
import StoreKit
import SwiftUI

enum PurchaseResult {
    case completed(isTrial: Bool)
    case cancelled
}

enum SubscriptionState: String {
    case none
    case trial
    case paid
}

@MainActor
class SubscriptionManager: ObservableObject {

    @Published var products: [String: Product] = [:]

    @Published var isLoading: Bool = false
    @Published var isSubscribed: Bool = false {
        didSet {
            storedIsSubscribed = isSubscribed
        }
    }
    @Published var activeProductId: String? = nil
    @Published var expirationDate: Date? = nil

    var planDisplayName: String? {
        switch activeProductId {
        case Self.monthlyProductId: return "Premium (Monthly)"
        case Self.yearlyProductId: return "Premium (Yearly)"
        default: return nil
        }
    }

    @AppStorage("storedIsSubscribed") private var storedIsSubscribed: Bool = false
    @AppStorage("storedSubscriptionState") private var storedSubscriptionStateRaw: String = SubscriptionState.none.rawValue

    private static var hasCheckedTransitions = false
    
    static let monthlyProductId = "nutrient.logger.premium.monthly"
    static let yearlyProductId = "nutrient.logger.premium.yearly"

    static let productIds = [
        monthlyProductId,
        yearlyProductId,
    ]
    
    private var transactionUpdates: Task<Void, Never>? = nil

    init(isForScreenshots: Bool = false) {
        refreshProducts()
        transactionUpdates = newTransactionListenerTask()
        
        if isForScreenshots {
            isSubscribed = true
            activeProductId = Self.yearlyProductId
            expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: .now)
        } else {
            isSubscribed = storedIsSubscribed
            Task {
                self.isSubscribed = await isSubscribed()
                await refreshEntitlementDetails()
            }
        }
    }
    
    func refreshProducts() {
        Task {
            await loadProducts()
        }
    }
    
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<StoreKit.Transaction>) {
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }

        if let _ = transaction.revocationDate {
            // Remove access to the product identified by transaction.productID.
            // Transaction.revocationReason provides details about
            // the revoked transaction.
            if Self.productIds.contains(transaction.productID) {
                isSubscribed = false
            }
        } else if let expirationDate = transaction.expirationDate,
            expirationDate < Date() {
            // Do nothing, this subscription is expired.
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            return
        } else {
            // Provide access to the product identified by
            // transaction.productID.
            if Self.productIds.contains(transaction.productID) {
                isSubscribed = true
            }
        }

        Task {
            await refreshEntitlementDetails()
        }
    }
    
    func loadProducts() async {
        do {
            isLoading = true
            products = .init(uniqueKeysWithValues: try await Product.products(for: Self.productIds).map { ($0.id, $0) })
            isLoading = false
            print("Loaded products: \(products)")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(productId: String? = nil) async throws -> PurchaseResult {
        let productId = productId ?? Self.productIds.first!
        guard let product = products[productId] else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                let isTrial = transaction.offerType == .introductory
                self.isSubscribed = true
                storedSubscriptionStateRaw = (isTrial ? SubscriptionState.trial : .paid).rawValue
                await transaction.finish()
                await refreshEntitlementDetails()
                return .completed(isTrial: isTrial)
            case .unverified:
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled:
            return .cancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    func isSubscribed() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                return Self.productIds.contains(transaction.productID)
            }
        }
        return false
    }

    /// Reads the active entitlement's product ID and expiration date, for display purposes
    /// (e.g. "Premium (Yearly), renews Jul 12, 2027" on the profile screen).
    func refreshEntitlementDetails() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, Self.productIds.contains(transaction.productID) {
                activeProductId = transaction.productID
                expirationDate = transaction.expirationDate
                return
            }
        }
        activeProductId = nil
        expirationDate = nil
    }

    func restorePurchases() async throws {
        try? await AppStore.sync()
        self.isSubscribed = await isSubscribed()
        await refreshEntitlementDetails()
    }

    func currentSubscriptionState() async -> SubscriptionState {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIds.contains(transaction.productID) {
                return transaction.offerType == .introductory ? .trial : .paid
            }
        }
        return .none
    }

    func checkSubscriptionTransitions(analytics: SubscriptionAnalytics) async {
        guard !Self.hasCheckedTransitions else { return }
        Self.hasCheckedTransitions = true

        let current = await currentSubscriptionState()
        let previous = SubscriptionState(rawValue: storedSubscriptionStateRaw) ?? .none

        if previous == .trial && current == .paid {
            analytics.subscriptionTrialConverted()
        } else if previous != .none && current == .none {
            analytics.subscriptionLapsed()
        }

        storedSubscriptionStateRaw = current.rawValue
    }
}


enum SubscriptionError: Error {
    case productNotFound
    case verificationFailed
    case pending
    case unknown
    
    var message: String {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .verificationFailed:
            return "Failed to verify purchase"
        case .pending:
            return "Purchase is pending"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
