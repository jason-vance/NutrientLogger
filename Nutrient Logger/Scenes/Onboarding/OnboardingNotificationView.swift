//
//  OnboardingNotificationView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI
import SwinjectAutoregistration

struct OnboardingNotificationView: View {

    let onContinue: () -> Void

    @Inject private var engagementAnalytics: EngagementAnalytics

    @State private var isRequesting = false

    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await NotificationManager().requestAuthorization()
            engagementAnalytics.notificationPermissionResult(granted ? .granted : .denied)
            isRequesting = false
            onContinue()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 48)

            Text("Do you want a gentle reminder?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 32)

            Text("A gentle daily nudge to log your meals, plus a heads up before you lose a streak. No spam, ever.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
                .padding(.top, 16)

            Spacer()

            OnboardingReviewQuote(
                quote: "I love this app, very user friendly and thorough!",
                author: "Kathrynnn G"
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            Button(action: requestPermission) {
                Text("Yes, Please")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isRequesting)
            .padding(.horizontal, 24)

            Button("Not Now") {
                engagementAnalytics.notificationPermissionResult(.dismissed)
                onContinue()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .disabled(isRequesting)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingNotificationView(onContinue: {})
    }
}
