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
            .readableContentWidth(marginsSkipSafeArea: true)
    }

    /// Keeps a scroll view's content to a comfortable column on wide screens (the unfolded iPhone
    /// Duo, iPad), centered, with the scroll indicator still at the screen edge. No effect on phones.
    /// `marginsSkipSafeArea` is for List, whose content margins count from its full edge (under
    /// side safe areas); a ScrollView's already start inside them.
    func readableContentWidth(_ maxWidth: CGFloat = .readableContentWidth, marginsSkipSafeArea: Bool = false) -> some View {
        modifier(ReadableContentWidth(maxWidth: maxWidth, marginsSkipSafeArea: marginsSkipSafeArea))
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

extension CGFloat {
    static let readableContentWidth: CGFloat = 640
}

private struct ReadableContentWidth: ViewModifier {
    let maxWidth: CGFloat
    let marginsSkipSafeArea: Bool
    @State private var margins = EdgeInsets()

    func body(content: Content) -> some View {
        content
            // Centers the column in the visible space, beside side safe areas such as the unfolded
            // iPhone Duo's tab column. nil keeps the system's margins on phones.
            .contentMargins(.leading, margins.leading > 0 ? margins.leading : nil, for: .scrollContent)
            .contentMargins(.trailing, margins.trailing > 0 ? margins.trailing : nil, for: .scrollContent)
            .onGeometryChange(for: EdgeInsets.self) { proxy in
                let extra = (proxy.size.width - maxWidth) / 2
                guard extra > 0 else { return EdgeInsets() }
                return EdgeInsets(
                    top: 0,
                    leading: (marginsSkipSafeArea ? proxy.safeAreaInsets.leading : 0) + extra,
                    bottom: 0,
                    trailing: (marginsSkipSafeArea ? proxy.safeAreaInsets.trailing : 0) + extra
                )
            } action: { margins = $0 }
    }
}
