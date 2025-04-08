//
//  UserService.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import UIKit

public protocol UserService {
    var currentUser: User { get }
    func save(user: User) async throws
}

public class DefaultUserService: UserService {
    
    private var userFileDir: URL {
        get { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
    }
    
    private let userFileName = "user.json"
    
    private var userFileUrl: URL {
        get { userFileDir.appendingPathComponent(userFileName) }
    }

    public var currentUser: User = User()

    public static func create() async -> UserService {
        let userService = DefaultUserService()
        await userService.load()
        return userService
    }

    public func save(user: User) async throws {
        currentUser = user
        try await saveUserToFile(user)
    }

    private func load() async {
        currentUser = await loadUserFromFile()
    }

    private func saveUserToFile(_ user: User) async throws {
        _ = try await Task.init(priority: .userInitiated) {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(user)
            try jsonData.write(to: self.userFileUrl)
        }.value
    }

    private func loadUserFromFile() async -> User {
        let task = Task.init(priority: .userInitiated) { () -> User in
            do {
                let jsonData = try Data(contentsOf: userFileUrl)
                return try JSONDecoder().decode(User.self, from: jsonData)
            } catch {
                print("Error loading user: \(error.localizedDescription)")
            }
            
            return User()
        }
        return await task.value
    }
}
