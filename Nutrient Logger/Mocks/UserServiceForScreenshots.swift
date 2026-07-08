//
//  UserServiceForScreenshots.swift
//  UserServiceForScreenshots
//
//  Created by Jason Vance on 9/21/21.
//

import Foundation

class UserServiceForScreenshots: UserService {
    public var currentUser: User {
        User(
            gender: .female,
            birthdate: .init(year: 1988, month: 5, day: 15),
            heightCm: 168,
            calorieGoal: 1700,
            carbsGoalGrams: 200,
            fatGoalGrams: 55,
            proteinGoalGrams: 100
        )
    }

    public func save(user: User) async throws {}
}
