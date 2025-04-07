//
//  User.swift
//  User
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation
import UIKit

public struct User: Codable {
    public static var birthdateNotSet = Date.distantPast
    
    public var gender: Gender = Gender.unknown
    public var birthdate: Date = birthdateNotSet
    public var preferredColorName: ColorName = ColorName.indigo
    public var preferredColor: UIColor { ColorPalettes.colorFrom(name: preferredColorName) }

    public func getUserAge() -> TimeInterval {
        return Date.now.timeIntervalSince(birthdate)
    }
}
