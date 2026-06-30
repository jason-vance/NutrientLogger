//
//  MockUserProfileAnalytics.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class MockUserProfileAnalytics: UserProfileAnalytics {
    
    public var gendersSet: [Gender] = [Gender]()
    public var birthdaysSet: [Date] = [Date]()

    public func userSetGender(_ gender: Gender) {
        gendersSet.append(gender)
    }

    public func userSetBirthdate(_ birthdate: Date) {
        birthdaysSet.append(birthdate)
    }
}
