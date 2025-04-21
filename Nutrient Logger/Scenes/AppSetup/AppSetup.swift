//
//  AppSetup.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import RijndaelSwift
import SwinjectAutoregistration
import Firebase

class AppSetup {
    
    static func doSetup() async {
        FirebaseApp.configure()
        
        setupAnalytics()
        
        registerAdProvider()
        registerNutrientRdiLibrary()
        await registerUserService()
        await registerRemoteDatabase()
        
//        doMocksForScreenshots()
    }
    
    fileprivate static func doMocksForScreenshots() {
        swinjectContainer.autoregister(AdProvider.self) { DefaultAdProvider(shouldShowAds: false) }
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
        swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
        //TODO: Add foods to modelContext for screenshots
//        swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
        //TODO: Add meals to modelContext for screenshots
//        swinjectContainer.autoregister(UserMealsDatabase.self) { UserMealsDatabaseForScreenshots() }
        swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    }
    
    private static func registerAdProvider() {
        let adProvider = DefaultAdProvider(shouldShowAds: true)
        swinjectContainer.autoregister(AdProvider.self) { adProvider }
    }
    
    private static func registerNutrientRdiLibrary() {
        let library = UsdaNutrientRdiLibrary.create()
        swinjectContainer.autoregister(NutrientRdiLibrary.self) { library }
    }
    
    private static func registerUserService() async {
        let userService = await DefaultUserService.create()
        swinjectContainer.autoregister(UserService.self) { userService }
    }
    
    private static func registerRemoteDatabase() async {
        let db = try! await BundledFdcDatabase()
        swinjectContainer.autoregister(RemoteDatabase.self) { db }
    }
    
    fileprivate static func setupAnalytics() {
        let analytics = DefaultAnalytics(analyticsEngine: FirebaseAnalytics())
        
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserProfileAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealsAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealAnalytics.self) { analytics }
        swinjectContainer.autoregister(ConsumedFoodSaverAnalytics.self) { analytics }
    }
}
