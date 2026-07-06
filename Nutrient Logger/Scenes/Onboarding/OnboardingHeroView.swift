//
//  OnboardingHeroView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI

struct OnboardingHeroView: View {

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "chart.bar.doc.horizontal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 48)

            Text("Track every vitamin,\nmineral, and amino acid.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)

            Text("Completely offline.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 16)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingHeroView(onContinue: {})
    }
}
