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

        registerNutrientRdiLibrary()
        await registerRemoteDatabase()

        if DataController.isScreenshots {
            setupMocksForScreenshots()
            await MainActor.run {
                ScreenshotDataSeeder.seed(into: DataController.shared.container.mainContext)
            }
        } else {
            setupAnalytics()
            await registerUserService()
        }
    }

    private static func setupMocksForScreenshots() {
        let analytics = DefaultAnalytics(analyticsEngine: MockAnalyticsEngine())
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserProfileAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealsAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealAnalytics.self) { analytics }
        swinjectContainer.autoregister(ConsumedFoodSaverAnalytics.self) { analytics }
        swinjectContainer.autoregister(SubscriptionAnalytics.self) { analytics }
        swinjectContainer.autoregister(EngagementAnalytics.self) { analytics }
        swinjectContainer.autoregister(PremiumAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
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
        swinjectContainer.autoregister(PremiumAnalytics.self) { analytics }
    }
}
