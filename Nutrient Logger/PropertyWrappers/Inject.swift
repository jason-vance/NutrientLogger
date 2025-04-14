//
//  Inject.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import Foundation
import SwinjectAutoregistration

@propertyWrapper struct Inject<T> {
    
    var wrappedValue: T {
        get {
            let t = swinjectContainer~>T.self
            return t
        }
        set { assertionFailure("You should not be setting this!") }
    }
}
