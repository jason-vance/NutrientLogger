//
//  ChoiceQuestion.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import SwiftUI

/// A question with every answer visible as a pill, and a line under it that explains the current
/// answer. Showing the options beats a menu that hides them: someone eating carnivore sees
/// "Carnivore" on screen and knows the app was built for them.
struct ChoiceQuestion<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option
    /// Explains the current answer, e.g. what the app will watch for this diet.
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LogFieldLabel(title)
            LogPillRow(
                items: options,
                labels: options.map(label),
                isSelected: { $0 == selection },
                onSelect: { option in withAnimation(.snappy) { selection = option } }
            )
            Text(note)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: note)
        }
    }
}
