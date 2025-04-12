//
//  AppSetup.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import RijndaelSwift
import SwinjectAutoregistration

class AppSetup {
    
    static func doSetup() async {
        //TODO: MVP: Uncomment when firebase is added
//        FirebaseApp.configure()
        
        setupAnalytics()
        setupAdProvider()
        
        registerNutrientRdiLibrary()
        await registerUserService()
        registerLocalDatabase()
        await registerUserMealsDatabase()
        await registerRemoteDatabase()
        registerFoodSaver()
        
//        doMocksForScreenshots()
    }
    
    fileprivate static func doMocksForScreenshots() {
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
        swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
        swinjectContainer.autoregister(AdProvider.self) { MockAdProvider() }
        swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
        swinjectContainer.autoregister(UserMealsDatabase.self) { UserMealsDatabaseForScreenshots() }
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
    
    private static func registerLocalDatabase() {
        let db = try! LocalSqliteDatabase()
        swinjectContainer.autoregister(LocalDatabase.self) { db }
    }
    
    private static func registerUserMealsDatabase() async {
        let db = try! await UserMealsSqliteDatabase()
        swinjectContainer.autoregister(UserMealsDatabase.self) { db }
    }
    
    private static func registerRemoteDatabase() async {
        let db = try! await BundledFdcDatabase()
        swinjectContainer.autoregister(RemoteDatabase.self) { db }
    }
    
    private static func registerFoodSaver() {
        let foodSaver = ConsumedFoodSaver(
            localDatabase: swinjectContainer~>LocalDatabase.self,
            analytics: swinjectContainer~>ConsumedFoodSaverAnalytics.self
        )
        swinjectContainer.autoregister(FoodSaver.self) { foodSaver }
    }
    
    //TODO: MVP: Uncomment when AdMob is added
    fileprivate static func setupAdProvider() {
        let adProvider = MockAdProvider()
        swinjectContainer.autoregister(AdProvider.self) { adProvider }
        return
//
//#if DEBUG
//        let adUnitId = GoogleAdProvider.testAdUnitId
//#else
//        let key = Data([
//            0xAE, 0x84, 0xB9, 0x52, 0x4D, 0x06, 0x86, 0x83, 0x17, 0xED, 0x56, 0x83, 0xB7, 0xDD, 0x2C, 0xA3,
//            0xE2, 0x0D, 0xD2, 0xCB, 0xF7, 0x0B, 0x59, 0xCC, 0x62, 0x41, 0x36, 0x72, 0xD5, 0x44, 0x85, 0x7C
//        ])
//        let iv = Data([
//            0xE2, 0x0D, 0xD2, 0xCB, 0xF7, 0x0B, 0x59, 0xCC, 0x62, 0x41, 0x36, 0x72, 0xD5, 0x44, 0x85, 0x7C,
//            0x82, 0xBA, 0x6B, 0x63, 0x53, 0x5F, 0x46, 0xE5, 0x02, 0x7F, 0xAA, 0xB6, 0xFF, 0xE2, 0x4D, 0xE6
//        ])
//        let r = Rijndael(key: key, mode: .cbc)!
//        
//        // adUnitId: "ca-app-pub-1475400719226569/6734098039"
//        let adUnitIdBase64 = Data(base64Encoded: "PSocwymmXgZ9+6cX1Y6sH0hU0ackkkavULsan6JbkHK7vk/TQ4RNxJ74pkNHbdc+qpK2Ua4Ia9vUbU04shqd5A==")!
//        let adUnitIdData = r.decryptString(data: adUnitIdBase64, blockSize: 32, iv: iv)!
//        let adUnitId = String(decoding: adUnitIdData, as: UTF8.self)
//#endif
//
//        IocContainer.shared.register(type: AdProvider.self, component: GoogleAdProvider(adUnitId: adUnitId))
    }
    
    fileprivate static func setupAnalytics() {
//        let analyticsEngine = FirebaseAnalytics()
        //TODO: MVP: Use FirebaseAnalytics engine when it is added
        let analytics = DefaultAnalytics(analyticsEngine: MockAnalyticsEngine())
        
        swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserProfileAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealsAnalytics.self) { analytics }
        swinjectContainer.autoregister(UserMealAnalytics.self) { analytics }
        swinjectContainer.autoregister(ConsumedFoodSaverAnalytics.self) { analytics }
    }
}
