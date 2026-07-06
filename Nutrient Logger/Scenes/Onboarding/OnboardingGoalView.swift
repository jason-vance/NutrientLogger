//
//  OnboardingGoalView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI

enum TrackingGoal: String, CaseIterable {
    case generalHealth = "general_health"
    case specificDeficiency = "specific_deficiency"
    case dietProtocol = "diet_protocol"

    var title: String {
        switch self {
        case .generalHealth: return "General Health"
        case .specificDeficiency: return "Specific Deficiency"
        case .dietProtocol: return "Diet Protocol"
        }
    }

    var subtitle: String {
        switch self {
        case .generalHealth: return "Stay balanced and feel your best"
        case .specificDeficiency: return "Identify and fix nutrient gaps"
        case .dietProtocol: return "Optimize for carnivore, keto, or vegan"
        }
    }

    var icon: String {
        switch self {
        case .generalHealth: return "heart.fill"
        case .specificDeficiency: return "magnifyingglass"
        case .dietProtocol: return "leaf.fill"
        }
    }
}

struct OnboardingGoalView: View {

    let onContinue: () -> Void

    @AppStorage("trackingGoal") private var selectedGoalRaw: String = ""

    private var selectedGoal: TrackingGoal? {
        TrackingGoal(rawValue: selectedGoalRaw)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("What are you\ntracking for?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, 48)
                .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                ForEach(TrackingGoal.allCases, id: \.rawValue) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        action: { selectedGoalRaw = goal.rawValue }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedGoal != nil ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedGoal == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder private func GoalCard(
        goal: TrackingGoal,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: goal.icon)
                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.6))
                        .font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(goal.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.white.opacity(0.3))
                    .font(.system(size: 22))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingGoalView(onContinue: {})
    }
}
