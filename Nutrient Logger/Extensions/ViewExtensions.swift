//
//  ViewExtensions.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import SwiftUI

extension View {
    
    func listDefaultModifiers() -> some View {
        self
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
    }
    
    func listRowDefaultModifiers() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
