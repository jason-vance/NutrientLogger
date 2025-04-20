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


protocol UserProfileAnalytics {
    func userSetGender(_ gender: Gender)
    func userSetBirthdate(_ birthdate: Date)
    func userSetPreferredColor(_ colorName: ColorName)
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

class DefaultAnalytics: NutrientLoggerAnalytics, UserProfileAnalytics, UserMealsAnalytics, UserMealAnalytics, ConsumedFoodSaverAnalytics {
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
    private let eventUserSetPreferredColor = "event_user_set_preferred_color"
    
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

    public func userSetPreferredColor(_ colorName: ColorName) {
        analytics.log(event: eventUserSetPreferredColor, parameters: [ analytics.parameterValue: colorName.value ])
    }
}
