//
//  Menu.swift
//  Menu
//
//  Created by Jason Vance on 8/23/21.
//

import Foundation

public class Menu {
    private(set) var meals: [Meal] = []

    public var isEmpty: Bool {
        get { meals.isEmpty }
    }

    public func add(_ meals: [Meal]) {
        self.meals.append(contentsOf: meals)
    }
}
