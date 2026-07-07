//
//  NutrientLoggerAnalytics.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import UIKit

protocol AnalyticsEngine {
    var eventSearch: String { get }
    var parameterSearchTerm: String { get }
    var parameterValue: String { get }

    func log(event: String)
    func log(event: String, parameters: [String:Any])
}


// MARK: - Subscription Funnel

enum PaywallTrigger: String {
    case smartPaywall = "smart_paywall"
    case deepLink = "deep_link"
    case micronutrientGoals = "micronutrient_goals"
    case removeAds = "remove_ads"
    case trendCharts = "trend_charts"
    case healthSync = "health_sync"
    case weightGoal = "weight_goal"
    case profileUpsell = "profile_upsell"
}

protocol SubscriptionAnalytics {
    func paywallShown(trigger: PaywallTrigger)
    func paywallDismissed(trigger: PaywallTrigger)
    func subscriptionPurchaseStarted(productId: String)
    func subscriptionPurchaseCompleted(productId: String, isTrial: Bool)
    func subscriptionPurchaseCancelled(productId: String)
    func subscriptionPurchaseFailed(productId: String, error: Error)
    func subscriptionRestored()
    func subscriptionTrialConverted()
    func subscriptionLapsed()
}


// MARK: - Feature Engagement & Retention

enum NotificationPermissionResult: String {
    case granted
    case denied
    case dismissed
}

protocol EngagementAnalytics {
    func screenViewed(screenName: String)
    func onboardingStepViewed(stepName: String, stepIndex: Int)
    func onboardingCompleted()
    func customFoodCreated()
    func customFoodEdited()
    func customFoodDeleted()
    func goalSet(goalName: String)
    func streakMilestoneReached(days: Int)
    func notificationPermissionResult(_ result: NotificationPermissionResult)
    func searchReturnedNoResults(query: String)
    func barcodeScanInitiated()
    func barcodeScanCompleted(found: Bool)
    func barcodeFallbackTaken(path: String)
    func healthSyncEnabled()
    func healthSyncDisabled()
    func weightLogged()
    func weightDeleted()
    func trendNutrientViewed(nutrientName: String)
}


protocol UserProfileAnalytics {
    func userSetGender(_ gender: Gender)
    func userSetBirthdate(_ birthdate: Date)
}

protocol UserMealsAnalytics {
    func loadMenuFailed(_ error: Error)
    func mealCreated()
    func mealCreationFailed(_ error: Error)
    func mealRenamed()
    func mealRenamingFailed(_ error: Error)
    func mealDeleted()
    func mealDeletingFailed(_ error: Error)
}

//TODO: Make sure these are being used
protocol UserMealAnalytics {
    func loadMealFailed(_ error: Error)
    func foodAddedToMeal(_ food: FoodItem)
    func addFoodToMealFailed(_ food: FoodItem)
    func foodDeletedFromMeal()
    func deletingFoodFromMealFailed(_ error: Error)
}

protocol PremiumAnalytics {
    func premiumFeatureTapped(feature: String)
}

protocol ConsumedFoodSaverAnalytics {
    func foodLogged(_ food: FoodItem)
    func foodLogFailed(_ food: FoodItem)
}

protocol NutrientLoggerAnalytics {
    func foodSearched(_ query: String)
    func unableToLeaveFeedback()
    func feedbackLeft()
    func nutrientNotMapped(_ nutrient: Nutrient)
    func errorLoadingDashboardNutrientData(_ error: Error)
    func errorLoadingFoodDetails(_ error: Error)
    func errorDeletingFood(_ error: Error)
    func errorLoadingFoodPortions(_ error: Error)
    func couldntAccessNutrientLibrary()
    func userClickedRemoveAds()
    func genericLoadIapException(_ error: Error)
    func noIapProductsFound(_ error: Error)
    func genericIapPurchaseException(_ error: Error)
    func genericIapRestoreException(_ error: Error)
    func removeAdsPurchased()
    func removeAdsRestored()
}

class DefaultAnalytics: NutrientLoggerAnalytics, UserProfileAnalytics, UserMealsAnalytics, UserMealAnalytics, ConsumedFoodSaverAnalytics, SubscriptionAnalytics, EngagementAnalytics, PremiumAnalytics {
    private let maxLength = 100

    private let eventFoodLogFailed = "food_log_failed"
    private let eventFoodLogged = "food_logged"
    private let parameterFoodFdcId = "food_fdc_id"
    private let parameterFoodFdcType = "food_fdc_type"
    private let parameterFoodName = "food_name"
    private let parameterFoodAmount = "food_amount"
    private let parameterFoodPortionName = "food_portion_name"
    private let parameterFoodGramWeight = "food_gram_weight"
    private let parameterFoodDateLogged = "food_date_logged"

    private let eventUnableToLeaveFeedback = "unable_to_leave_feedback"
    private let eventFeedbackLeft = "feedback_left"

    private let eventNutrientNotMapped = "nutrient_not_mapped"
    private let parameterNutrientFdcNumber = "nutrient_fdc_number"
    private let parameterNutrientName = "nutrient_name"

    private let eventErrorLoadingDashboardNutrientData = "error_loading_dashboard_nutrient_data"
    private let eventErrorLoadingFoodDetails = "error_loading_food_details"
    private let eventErrorDeletingFood = "error_deleting_food"
    private let eventErrorLoadingFoodPortions = "error_loading_food_portions"
    private let parameterErrorMessage = "error_message"

    private let eventCouldntAccessNutrientLibrary = "couldnt_access_nutrient_library"

    private let eventLoadMenuFailed = "event_load_menu_failed"
    private let eventMealCreated = "event_meal_created"
    private let eventMealCreationFailed = "event_meal_creation_failed"
    private let eventLoadMealFailed = "event_load_meal_failed"
    private let eventFoodAddedToMeal = "event_food_added_to_meal"
    private let eventAddFoodtoMealFailed = "event_add_food_to_meal_failed"
    private let eventMealRenamingFailed = "event_meal_renaming_failed"
    private let eventMealRenamed = "event_meal_renamed"
    private let eventMealDeleted = "event_meal_deleted"
    private let eventMealDeletingFailed = "event_meal_deleting_failed"
    private let eventFoodDeletedFromMeal = "event_food_deleted_from_meal"
    private let eventDeletingFoodFromMealFailed = "event_deleting_food_from_meal_failed"

    private let eventUserClickedRemoveAds = "event_user_clicked_remove_ads"
    private let eventGenericLoadIapException = "event_generic_load_iap_exception"
    private let eventNoIapProductsFound = "event_no_iap_products_found"
    private let eventGenericIapPurchaseException = "event_generic_iap_purchase_exception"
    private let eventGenericIapRestoreException = "event_generic_iap_restore_exception"
    private let eventRemoveAdsPurchased = "event_remove_ads_purchased"
    private let eventRemoveAdsRestored = "event_remove_ads_restored"

    private let eventUserSetGender = "event_user_set_gender"
    private let eventUserSetBirthdate = "event_user_set_birthdate"

    let analytics: AnalyticsEngine
    
    public init(analyticsEngine: AnalyticsEngine) {
        analytics = analyticsEngine
    }

    private func addFoodToDictionary(_ food: FoodItem, _ dict: inout [String:Any]) {
        dict[parameterFoodFdcId] = food.fdcId
        dict[parameterFoodFdcType] = food.fdcType
        dict[parameterFoodName] = food.name
        dict[parameterFoodAmount] = food.amount
        dict[parameterFoodPortionName] = food.portionName
        dict[parameterFoodGramWeight] = food.gramWeight
        dict[parameterFoodDateLogged] = food.dateLogged
    }

    private func addExceptionToDictionary(_ e: Error, _ dict: inout [String:Any]) {
        let msg = e.localizedDescription.prefix(maxLength)
        dict[parameterErrorMessage] = msg
    }

    public func foodSearched(_ query: String) {
        analytics.log(event: analytics.eventSearch, parameters: [ analytics.parameterSearchTerm: query ])
    }

    public func foodLogged(_ food: FoodItem) {
        var dict = [String:Any]()
        addFoodToDictionary(food, &dict)
        analytics.log(event: eventFoodLogged, parameters: dict)
        recordTimeToFirstLogIfNeeded()
    }

    // MARK: - Time to First Log

    private let keyOnboardingCompletedAt = "onboardingCompletedAt"
    private let keyHasLoggedFirstFood = "hasLoggedFirstFood"
    private let eventTimeToFirstLog = "time_to_first_log"
    private let parameterSeconds = "seconds"

    // Only fires for users who completed the current onboarding flow (which stamps
    // onboardingCompletedAt), so migrated/existing users don't skew the metric.
    private func recordTimeToFirstLogIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: keyHasLoggedFirstFood) else { return }
        defaults.set(true, forKey: keyHasLoggedFirstFood)

        let onboardingCompletedAt = defaults.double(forKey: keyOnboardingCompletedAt)
        guard onboardingCompletedAt > 0 else { return }

        let seconds = Date.now.timeIntervalSince1970 - onboardingCompletedAt
        analytics.log(event: eventTimeToFirstLog, parameters: [parameterSeconds: seconds])
    }

    public func foodLogFailed(_ food: FoodItem) {
        var dict = [String:Any]()
        addFoodToDictionary(food, &dict)
        analytics.log(event: eventFoodLogFailed, parameters: dict)
    }

    public func unableToLeaveFeedback() {
        analytics.log(event: eventUnableToLeaveFeedback)
    }

    public func feedbackLeft() {
        analytics.log(event: eventFeedbackLeft)
    }

    public func nutrientNotMapped(_ nutrient: Nutrient) {
        var dict = [String:Any]()

        dict[parameterNutrientFdcNumber] = nutrient.fdcNumber
        dict[parameterNutrientName] = nutrient.name

        analytics.log(event: eventNutrientNotMapped, parameters: dict)
    }

    public func errorLoadingDashboardNutrientData(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventErrorLoadingDashboardNutrientData, parameters: dict)
    }

    public func errorLoadingFoodDetails(_ e: Error)  {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventErrorLoadingFoodDetails, parameters: dict)
    }

    public func errorDeletingFood(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventErrorDeletingFood, parameters: dict)
    }

    public func errorLoadingFoodPortions(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventErrorLoadingFoodPortions, parameters: dict)
    }

    public func couldntAccessNutrientLibrary() {
        analytics.log(event: eventCouldntAccessNutrientLibrary)
    }
    
    public func loadMenuFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventLoadMenuFailed, parameters: dict)
    }

    public func mealCreated() {
        analytics.log(event: eventMealCreated)
    }
    
    public func mealCreationFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventMealCreationFailed, parameters: dict)
    }
    
    public func loadMealFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventLoadMealFailed, parameters: dict)
    }

    public func foodAddedToMeal(_ food: FoodItem) {
        var dict = [String:Any]()
        addFoodToDictionary(food, &dict)
        analytics.log(event: eventFoodAddedToMeal, parameters: dict)
    }

    public func addFoodToMealFailed(_ food: FoodItem) {
        var dict = [String:Any]()
        addFoodToDictionary(food, &dict)
        analytics.log(event: eventAddFoodtoMealFailed, parameters: dict)
    }

    public func mealRenamingFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventMealRenamingFailed, parameters: dict)
    }

    public func mealRenamed() {
        analytics.log(event: eventMealRenamed)
    }

    public func mealDeleted() {
        analytics.log(event: eventMealDeleted)
    }

    public func mealDeletingFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventMealDeletingFailed, parameters: dict)
    }

    public func foodDeletedFromMeal() {
        analytics.log(event: eventFoodDeletedFromMeal)
    }

    public func deletingFoodFromMealFailed(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventDeletingFoodFromMealFailed, parameters: dict)
    }

    public func userClickedRemoveAds() {
        analytics.log(event: eventUserClickedRemoveAds)
    }

    public func genericLoadIapException(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventGenericLoadIapException, parameters: dict)
    }

    public func noIapProductsFound(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventNoIapProductsFound, parameters: dict)
    }

    public func genericIapPurchaseException(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventGenericIapPurchaseException, parameters: dict)
    }

    public func genericIapRestoreException(_ e: Error) {
        var dict = [String:Any]()
        addExceptionToDictionary(e, &dict)
        analytics.log(event: eventGenericIapRestoreException, parameters: dict)
    }

    public func removeAdsPurchased() {
        analytics.log(event: eventRemoveAdsPurchased)
    }

    public func removeAdsRestored() {
        analytics.log(event: eventRemoveAdsRestored)
    }

    public func userSetGender(_ gender: Gender) {
        analytics.log(event: eventUserSetGender, parameters: [ analytics.parameterValue: gender.rawValue ])
    }

    public func userSetBirthdate(_ birthdate: Date) {
        analytics.log(event: eventUserSetBirthdate, parameters: [ analytics.parameterValue: birthdate ])
    }

    // MARK: - Subscription Funnel

    private let eventPaywallShown = "paywall_shown"
    private let eventPaywallDismissed = "paywall_dismissed"
    private let eventSubscriptionPurchaseStarted = "subscription_purchase_started"
    private let eventSubscriptionPurchaseCompleted = "subscription_purchase_completed"
    private let eventSubscriptionPurchaseCancelled = "subscription_purchase_cancelled"
    private let eventSubscriptionPurchaseFailed = "subscription_purchase_failed"
    private let eventSubscriptionRestored = "subscription_restored"
    private let eventSubscriptionTrialConverted = "subscription_trial_converted"
    private let eventSubscriptionLapsed = "subscription_lapsed"
    private let parameterTrigger = "trigger"
    private let parameterProductId = "product_id"
    private let parameterIsTrial = "is_trial"

    public func paywallShown(trigger: PaywallTrigger) {
        analytics.log(event: eventPaywallShown, parameters: [parameterTrigger: trigger.rawValue])
    }

    public func paywallDismissed(trigger: PaywallTrigger) {
        analytics.log(event: eventPaywallDismissed, parameters: [parameterTrigger: trigger.rawValue])
    }

    public func subscriptionPurchaseStarted(productId: String) {
        analytics.log(event: eventSubscriptionPurchaseStarted, parameters: [parameterProductId: productId])
    }

    public func subscriptionPurchaseCompleted(productId: String, isTrial: Bool) {
        analytics.log(event: eventSubscriptionPurchaseCompleted, parameters: [
            parameterProductId: productId,
            parameterIsTrial: isTrial,
        ])
    }

    public func subscriptionPurchaseCancelled(productId: String) {
        analytics.log(event: eventSubscriptionPurchaseCancelled, parameters: [parameterProductId: productId])
    }

    public func subscriptionPurchaseFailed(productId: String, error: Error) {
        var dict: [String: Any] = [parameterProductId: productId]
        addExceptionToDictionary(error, &dict)
        analytics.log(event: eventSubscriptionPurchaseFailed, parameters: dict)
    }

    public func subscriptionRestored() {
        analytics.log(event: eventSubscriptionRestored)
    }

    public func subscriptionTrialConverted() {
        analytics.log(event: eventSubscriptionTrialConverted)
    }

    public func subscriptionLapsed() {
        analytics.log(event: eventSubscriptionLapsed)
    }

    // MARK: - Feature Engagement & Retention

    private let eventScreenViewed = "screen_viewed"
    private let parameterScreenName = "screen_name"

    private let eventCustomFoodCreated = "custom_food_created"
    private let eventCustomFoodEdited = "custom_food_edited"
    private let eventCustomFoodDeleted = "custom_food_deleted"
    private let eventGoalSet = "goal_set"
    private let eventStreakMilestoneReached = "streak_milestone_reached"
    private let eventNotificationPermissionResult = "notification_permission_result"
    private let eventSearchNoResults = "search_no_results"
    private let parameterGoalName = "goal_name"
    private let parameterStreakDays = "streak_days"
    private let parameterResult = "result"

    public func screenViewed(screenName: String) {
        analytics.log(event: eventScreenViewed, parameters: [parameterScreenName: screenName])
    }

    private let eventOnboardingStepViewed = "onboarding_step_viewed"
    private let eventOnboardingCompleted = "onboarding_completed"
    private let parameterStepName = "step_name"
    private let parameterStepIndex = "step_index"

    public func onboardingStepViewed(stepName: String, stepIndex: Int) {
        analytics.log(event: eventOnboardingStepViewed, parameters: [
            parameterStepName: stepName,
            parameterStepIndex: stepIndex,
        ])
    }

    public func onboardingCompleted() {
        analytics.log(event: eventOnboardingCompleted)
    }

    public func customFoodCreated() {
        analytics.log(event: eventCustomFoodCreated)
    }

    public func customFoodEdited() {
        analytics.log(event: eventCustomFoodEdited)
    }

    public func customFoodDeleted() {
        analytics.log(event: eventCustomFoodDeleted)
    }

    public func goalSet(goalName: String) {
        analytics.log(event: eventGoalSet, parameters: [parameterGoalName: goalName])
    }

    public func streakMilestoneReached(days: Int) {
        analytics.log(event: eventStreakMilestoneReached, parameters: [parameterStreakDays: days])
    }

    public func notificationPermissionResult(_ result: NotificationPermissionResult) {
        analytics.log(event: eventNotificationPermissionResult, parameters: [parameterResult: result.rawValue])
    }

    public func searchReturnedNoResults(query: String) {
        analytics.log(event: eventSearchNoResults, parameters: [analytics.parameterSearchTerm: query])
    }

    private let eventBarcodeScanInitiated = "barcode_scan_initiated"
    private let eventBarcodeScanCompleted = "barcode_scan_completed"
    private let eventBarcodeFallbackTaken = "barcode_fallback_taken"
    private let parameterFound = "found"
    private let parameterPath = "path"

    public func barcodeScanInitiated() {
        analytics.log(event: eventBarcodeScanInitiated)
    }

    public func barcodeScanCompleted(found: Bool) {
        analytics.log(event: eventBarcodeScanCompleted, parameters: [parameterFound: found])
    }

    public func barcodeFallbackTaken(path: String) {
        analytics.log(event: eventBarcodeFallbackTaken, parameters: [parameterPath: path])
    }

    private let eventHealthSyncEnabled = "health_sync_enabled"
    private let eventHealthSyncDisabled = "health_sync_disabled"

    public func healthSyncEnabled() {
        analytics.log(event: eventHealthSyncEnabled)
    }

    public func healthSyncDisabled() {
        analytics.log(event: eventHealthSyncDisabled)
    }

    private let eventWeightLogged = "weight_logged"
    private let eventWeightDeleted = "weight_deleted"

    public func weightLogged() {
        analytics.log(event: eventWeightLogged)
    }

    public func weightDeleted() {
        analytics.log(event: eventWeightDeleted)
    }

    private let eventTrendNutrientViewed = "trend_nutrient_viewed"
    private let parameterNutrient = "nutrient"

    public func trendNutrientViewed(nutrientName: String) {
        analytics.log(event: eventTrendNutrientViewed, parameters: [parameterNutrient: nutrientName])
    }

    // MARK: - Premium Feature Engagement

    private let eventPremiumFeatureTapped = "premium_feature_tapped"
    private let parameterFeature = "feature"

    public func premiumFeatureTapped(feature: String) {
        analytics.log(event: eventPremiumFeatureTapped, parameters: [parameterFeature: feature])
    }
}
