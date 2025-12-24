//
//  SubscriptionManager.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 12/23/25.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    
    @Published var products: [String: Product] = [:]
    
    @Published var isLoading: Bool = false
    @Published var isSubscribed: Bool = false {
        didSet {
            storedIsSubscribed = isSubscribed
        }
    }
    
    @AppStorage("storedIsSubscribed") private var storedIsSubscribed: Bool = false
    
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
        } else {
            isSubscribed = storedIsSubscribed
            Task {
                self.isSubscribed = await isSubscribed()
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
    
    func purchase(productId: String? = nil) async throws -> Bool {
        let productId = productId ?? Self.productIds.first!
        guard let product = products[productId] else {
            throw SubscriptionError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check if the transaction is verified
            switch verification {
            case .verified(let transaction):
                // Update the user's subscription status
                self.isSubscribed = true
                await transaction.finish()
                return true
            case .unverified:
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled:
            self.isSubscribed = false
            return false
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
    
    func restorePurchases() async throws {
        try? await AppStore.sync()
        self.isSubscribed = await isSubscribed()
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
