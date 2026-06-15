//
//  NotificationPermissionPromptView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import SwiftUI

/// Shown once, after the user's first launch, to explain and request notification permission
/// for the daily logging reminder and streak-at-risk alert.
struct NotificationPermissionPromptView: View {

    let onComplete: () -> Void

    @State private var isRequesting = false

    private func requestPermission() {
        isRequesting = true
        Task {
            await NotificationManager().requestAuthorization()
            isRequesting = false
            onComplete()
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Stay on Track")
                .font(.title.bold())

            Text("Turn on notifications for a gentle daily reminder to log your meals, and a heads up before you lose a logging streak.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            EnableNotificationsButton()
            NotNowButton()
        }
        .padding(.bottom, 32)
    }

    @ViewBuilder private func EnableNotificationsButton() -> some View {
        Button {
            requestPermission()
        } label: {
            Text("Enable Notifications")
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color.white)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: .infinity, style: .continuous)
                        .foregroundStyle(Color.accentColor.gradient)
                }
        }
        .disabled(isRequesting)
        .padding(.horizontal, 32)
    }

    @ViewBuilder private func NotNowButton() -> some View {
        Button("Not Now") {
            onComplete()
        }
        .foregroundStyle(.secondary)
        .disabled(isRequesting)
        .padding(.top, 8)
    }
}

#Preview {
    NotificationPermissionPromptView(onComplete: {})
}
