//
//  MockUserMealsAnalytics.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class MockUserMealsAnalytics: UserMealsAnalytics {
    
    public var loadMealErrors = [Error]()
    public var mealsCreated = 0
    public var mealCreationErrors = [Error]()
    public var mealsRenamed = 0
    public var mealRenamingErrors = [Error]()
    public var mealsDeleted = 0
    public var mealDeletionErrors = [Error]()
    
    public func loadMenuFailed(_ error: Error) {
        loadMealErrors.append(error)
    }
    
    public func mealCreated() {
        mealsCreated += 1
    }
    
    public func mealCreationFailed(_ error: Error) {
        mealCreationErrors.append(error)
    }
    
    public func mealRenamed() {
        mealsRenamed += 1
    }
    
    public func mealRenamingFailed(_ error: Error) {
        mealRenamingErrors.append(error)
    }
    
    public func mealDeleted() {
        mealsDeleted += 1
    }
    
    public func mealDeletingFailed(_ error: Error) {
        mealDeletionErrors.append(error)
    }
    
    
}
