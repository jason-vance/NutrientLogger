//
//  Haptics.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/17/26.
//

import UIKit

/// Haptics for actions that end by closing their own view (logging a food, say), where SwiftUI's
/// `.sensoryFeedback` would have nothing left on screen to play from. Views that stay on screen
/// use `.sensoryFeedback` instead.
enum Haptics {

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
