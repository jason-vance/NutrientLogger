//
//  PremiumUnlockedToast.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/17/26.
//

import SwiftUI

/// After a purchase, a card drops in at the top of the app, its lock opens, and it says thanks.
/// Applied once at the root so it covers every paywall (onboarding, the first-day recap, the
/// marketing screen). It waits for the paywall to close so the moment lands on the app.
struct PremiumUnlockedToast: ViewModifier {

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowing = false
    @State private var isUnlocked = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isShowing {
                    Card()
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .onTapGesture { withAnimation(.smooth) { isShowing = false } }
                }
            }
            .onChange(of: subscriptionManager.completedPurchases) { show() }
            .sensoryFeedback(.success, trigger: isUnlocked) { _, isUnlocked in isUnlocked }
    }

    private func show() {
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            isUnlocked = false
            withAnimation(.snappy) { isShowing = true }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.snappy) { isUnlocked = true }
            AccessibilityNotification.Announcement("Premium unlocked").post()
            try? await Task.sleep(for: .seconds(2.6))
            withAnimation(.smooth) { isShowing = false }
        }
    }

    @ViewBuilder private func Card() -> some View {
        HStack(spacing: 14) {
            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("Premium unlocked")
                    .font(.headline)
                Text("Thanks for supporting Nutrient Logger.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}
