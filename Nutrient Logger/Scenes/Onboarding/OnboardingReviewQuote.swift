//
//  OnboardingReviewQuote.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/16/26.
//

import SwiftUI

/// A compact, unobtrusive 5-star App Store review used to sprinkle social proof
/// into the onboarding flow without competing with each screen's primary CTA.
struct OnboardingReviewQuote: View {

    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.yellow)
                }
            }

            Text("\u{201C}\(quote)\u{201D}")
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.opacity(0.8))

            Text("\u{2014} \(author)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        OnboardingReviewQuote(
            quote: "Free and great insight about vitamin and mineral intake.",
            author: "SoaresEM"
        )
        .padding()
    }
}
