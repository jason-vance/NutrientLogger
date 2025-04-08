//
//  DatabaseEntity.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public protocol DatabaseEntity: Identifiable {
    var id: Int { get set }
    var created: Date { get set }
}
