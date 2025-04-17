//
//  User.swift
//  User
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation
import SwiftUI

struct User: Codable {
    
    public var gender: Gender = Gender.unknown
    public var birthdate: SimpleDate? = nil
    public var preferredColorName: ColorName = ColorName.indigo
    public var preferredColor: Color { ColorPalettes.colorFrom(name: preferredColorName) }

    public func getUserAge() -> TimeInterval? {
        guard let birthdate = birthdate?.toDate() else { return nil }
        return Date.now.timeIntervalSince(birthdate)
    }
    
    public static let sample: User = .init(
        gender: .male,
        birthdate: .init(year: 1987, month: 6, day: 16),
        preferredColorName: .indigo
    )
}

extension User: Equatable { }
