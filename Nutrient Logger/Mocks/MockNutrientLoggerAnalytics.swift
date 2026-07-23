//
//  MockNutrientLoggerAnalytics.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import Foundation

class MockSubscriptionAnalytics: SubscriptionAnalytics {
    func paywallShown(trigger: PaywallTrigger) {}
    func paywallDismissed(trigger: PaywallTrigger) {}
    func subscriptionPurchaseStarted(productId: String) {}
    func subscriptionPurchaseCompleted(productId: String, isTrial: Bool) {}
    func subscriptionPurchaseCancelled(productId: String) {}
    func subscriptionPurchaseFailed(productId: String, error: Error) {}
    func subscriptionRestored() {}
    func subscriptionTrialConverted() {}
    func subscriptionLapsed() {}
}

class MockPremiumAnalytics: PremiumAnalytics {
    func premiumFeatureTapped(feature: String) {}
}

class MockEngagementAnalytics: EngagementAnalytics {
    func screenViewed(screenName: String) {}
    func onboardingStepViewed(stepName: String, stepIndex: Int) {}
    func onboardingPersonalizationSelected(diet: String, concern: String) {}
    func onboardingCompleted() {}
    func customFoodCreated() {}
    func customFoodEdited() {}
    func customFoodDeleted() {}
    func goalSet(goalName: String) {}
    func streakMilestoneReached(days: Int) {}
    func notificationPermissionResult(_ result: NotificationPermissionResult) {}
    func searchReturnedNoResults(query: String) {}
    func barcodeScanInitiated() {}
    func barcodeScanCompleted(found: Bool) {}
    func barcodeFallbackTaken(path: String) {}
    func healthSyncEnabled() {}
    func healthSyncDisabled() {}
    func weightLogged() {}
    func weightDeleted() {}
    func trendNutrientViewed(nutrientName: String) {}
    func dataExported(foodCount: Int) {}
}

class MockNutrientLoggerAnalytics: NutrientLoggerAnalytics {
    func foodSearched(_ query: String) {
    }
    
    func unableToLeaveFeedback() {
    }
    
    func feedbackLeft() {
    }
    
    func nutrientNotMapped(_ nutrient: Nutrient) {
    }
    
    func errorLoadingDashboardNutrientData(_ error: any Error) {
    }
    
    func errorLoadingFoodDetails(_ error: any Error) {
    }
    
    func errorDeletingFood(_ error: any Error) {
    }
    
    func errorLoadingFoodPortions(_ error: any Error) {
    }
    
    func couldntAccessNutrientLibrary() {
    }
}
