//
//  MockUserService.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

class MockUserService: UserService {
    
    public var currentUser: User
    
    public init(currentUser: User) {
        self.currentUser = currentUser
    }
    
    public func save(user: User) async throws {
        currentUser = user
    }
}
