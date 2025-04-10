//
//  MockNutrientLoggerAnalytics.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import Foundation

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
    
    func userClickedRemoveAds() {
    }
    
    func genericLoadIapException(_ error: any Error) {
    }
    
    func noIapProductsFound(_ error: any Error) {
    }
    
    func genericIapPurchaseException(_ error: any Error) {

    }
    
    func genericIapRestoreException(_ error: any Error) {
    }
    
    func removeAdsPurchased() {
    }
    
    func removeAdsRestored() {
    }
}
