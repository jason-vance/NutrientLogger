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
    
    func listSectionHeader() -> some View {
        self
            .font(.footnote)
            .textCase(.uppercase)
            .opacity(0.5)
            .listRowDefaultModifiers()
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
    
    func inCard(backgroundColor: Color = .background, cornerRadius: CGFloat = .cornerRadiusListRow) -> some View {
        self
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.shadow(.drop(color: backgroundColor.opacity(.cardShadowColorOpacity), radius: .shadowRadiusDefault)))
                        .fill(Color.background)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor.opacity(.cardBackgroundColorOpacity).gradient)
                }
            }
    }
}
