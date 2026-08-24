//
//  PremiumCTARow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/21/26.
//

import SwiftUI

struct PremiumCTARow: View {

    let trigger: PaywallTrigger
    let size: PremiumCTASize

    @State private var showMarketingView = false

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    private var teaser: String {
        switch trigger {
        case .smartPaywall, .deepLink, .profileUpsell:
            return "Unlock every Premium feature"
        case .trendCharts:
            return "See 7 & 30-day nutrient trends"
        case .weightGoal:
            return "Track weight & body fat goals"
        case .micronutrientGoals:
            return "Set custom micronutrient goals & limits"
        case .csvExport:
            return "Export your data to CSV"
        case .healthSync:
            return "Sync with Apple Health"
        case .weeklyNutrientWatch:
            return "Get weekly nutrient alerts"
        }
    }

    var body: some View {
        if subscriptionManager.isSubscribed {
            EmptyView()
        } else {
            Button {
                showMarketingView = true
            } label: {
                content
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showMarketingView) {
                MarketingView(trigger: trigger)
            }
            .listRowDefaultModifiers()
        }
    }

    @ViewBuilder private var content: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(teaser)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                if size == .medium {
                    Text("Tap to see what's included")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, size == .medium ? 16 : 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .foregroundStyle(Color.accentColor.opacity(0.12))
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(SubscriptionAnalytics.self) { MockSubscriptionAnalytics() }
    List {
        PremiumCTARow(trigger: .smartPaywall, size: .small)
        PremiumCTARow(trigger: .trendCharts, size: .medium)
    }
    .environmentObject(SubscriptionManager())
}
