//
//  UserServiceForScreenshots.swift
//  UserServiceForScreenshots
//
//  Created by Jason Vance on 9/21/21.
//

import Foundation

public class UserServiceForScreenshots: UserService {
    public var currentUser: User {
        User(
            gender: .female,
            birthdate: Date.from(year: 1988, month: 5, day: 15),
            preferredColorName: ColorName.indigo)
    }
    
    public func save(user: User) async throws {}
}
