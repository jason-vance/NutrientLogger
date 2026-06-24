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
        #if !DEBUG
        FirebaseApp.configure()
        #endif

        setupAnalytics()
        
        registerNutrientRdiLibrary()
        await registerUserService()
        await registerRemoteDatabase()
        
//        doMocksForScreenshots()
    }
    
    fileprivate static func doMocksForScreenshots() {
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
        swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
        //TODO: Add foods to modelContext for screenshots
//        swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
        //TODO: Add meals to modelContext for screenshots
//        swinjectContainer.autoregister(UserMealsDatabase.self) { UserMealsDatabaseForScreenshots() }
        swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
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
        let fdc = try! await BundledFdcDatabase()
        let composite = await CompositeRemoteDatabase(fdc: fdc, custom: .shared)
        swinjectContainer.autoregister(RemoteDatabase.self) { composite }
    }
    
    fileprivate static func setupAnalytics() {
        #if DEBUG
        let analytics = DefaultAnalytics(analyticsEngine: MockAnalyticsEngine())
        #else
        let analytics = DefaultAnalytics(analyticsEngine: FirebaseAnalytics())
        #endif
        
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserProfileAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealsAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealAnalytics.self) { analytics }
        swinjectContainer.autoregister(ConsumedFoodSaverAnalytics.self) { analytics }
        swinjectContainer.autoregister(SubscriptionAnalytics.self) { analytics }
        swinjectContainer.autoregister(EngagementAnalytics.self) { analytics }
    }
}
