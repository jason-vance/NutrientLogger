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
    
    func listSubsectionHeader() -> some View {
        self
            .font(.footnote.bold())
            .listRowDefaultModifiers()
    }
    
    func underlined(_ isUnderlined: Bool = true, color: Color, lineWidth: CGFloat = 1) -> some View {
        self
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isUnderlined ? color : Color.clear)
                    .frame(height: lineWidth)
            }
    }
}
