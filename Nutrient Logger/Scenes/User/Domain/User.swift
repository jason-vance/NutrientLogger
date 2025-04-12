//
//  User.swift
//  User
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation
import UIKit

//TODO: MVP: Change birthdate to SimpleDate
public struct User: Codable {
    
    public static var birthdateNotSet = Date.distantPast
    
    public var gender: Gender = Gender.unknown
    public var birthdate: Date = birthdateNotSet
    public var preferredColorName: ColorName = ColorName.indigo
    public var preferredColor: UIColor { ColorPalettes.colorFrom(name: preferredColorName) }

    public func getUserAge() -> TimeInterval {
        return Date.now.timeIntervalSince(birthdate)
    }
    
    public static let sample: User = .init(
        gender: .male,
        birthdate: .from(year: 1987, month: 6, day: 16),
        preferredColorName: .indigo
    )
}
