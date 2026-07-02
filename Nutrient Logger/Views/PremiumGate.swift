//
//  PremiumGate.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import SwiftUI
import SwinjectAutoregistration

/// Wraps content that requires a subscription. Free users see the content dimmed with a
/// "Premium" badge; tapping opens the paywall. Subscribers see content normally.
struct PremiumGate<Content: View>: View {

    let trigger: PaywallTrigger
    let feature: String
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Inject private var premiumAnalytics: PremiumAnalytics

    @State private var showMarketingView: Bool = false

    var body: some View {
        if subscriptionManager.isSubscribed {
            content()
        } else {
            content()
                .disabled(true)
                .opacity(0.4)
                .overlay { LockBadge() }
                .contentShape(Rectangle())
                .onTapGesture {
                    premiumAnalytics.premiumFeatureTapped(feature: feature)
                    showMarketingView = true
                }
                .sheet(isPresented: $showMarketingView) {
                    MarketingView(trigger: trigger)
                }
        }
    }

    @ViewBuilder private func LockBadge() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
            Text("Premium")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background { Capsule().foregroundStyle(Color.accentColor.gradient) }
    }
}

#Preview("Free user") {
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }
    PremiumGate(trigger: .weightGoal, feature: "weight_goal") {
        VStack(spacing: 0) {
            HStack {
                Text("Weight Goal")
                Spacer()
                Text("175 lbs").bold()
            }
            .padding()
            Divider()
            HStack {
                Text("Body Fat Goal")
                Spacer()
                Text("18%").bold()
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .environmentObject(SubscriptionManager(isForScreenshots: false))
}

#Preview("Subscriber") {
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }
    PremiumGate(trigger: .weightGoal, feature: "weight_goal") {
        VStack(spacing: 0) {
            HStack {
                Text("Weight Goal")
                Spacer()
                Text("175 lbs").bold()
            }
            .padding()
            Divider()
            HStack {
                Text("Body Fat Goal")
                Spacer()
                Text("18%").bold()
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .environmentObject(SubscriptionManager(isForScreenshots: true))
}

