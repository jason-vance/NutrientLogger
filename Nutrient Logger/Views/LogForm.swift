//
//  LogForm.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import SwiftUI

// The pieces shared by the screens that log something (Food Details, Log Meal): one-tap choice
// pills, the date and meal pickers, and the main button that reads back what will be logged.

/// A one-tap choice. Selected is a solid accent fill; everything else is a quiet gray fill, so the
/// picked options are what you read first.
struct LogPill: View {
    let text: String
    let isSelected: Bool
    var font: Font = .subheadline
    var fillsWidth: Bool = false

    var body: some View {
        Text(text)
            .font(font.weight(isSelected ? .semibold : .regular))
            .lineLimit(1)
            .minimumScaleFactor(fillsWidth ? 0.7 : 1)
            .padding(.horizontal, fillsWidth ? 6 : 12)
            .padding(.vertical, 7)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(Capsule().fill(isSelected ? Color.accentColor : Color.gray.opacity(0.18)))
            .contentShape(Capsule())
    }
}

/// Choices that wrap onto more lines as needed, so every option stays visible inside the card.
/// `moreCount` adds a "+ N more" pill in the same shape, with accent text.
struct LogPillRow<Item: Hashable>: View {
    let items: [Item]
    let labels: [String]
    let isSelected: (Item) -> Bool
    let onSelect: (Item) -> Void
    var moreCount: Int = 0
    var onMore: () -> Void = {}

    var body: some View {
        FlowLayout(spacing: 8) {
            // Keyed by item so revealing more pills slides new ones in instead of relabeling old ones.
            ForEach(Array(zip(items, labels)), id: \.0) { item, label in
                Button {
                    onSelect(item)
                } label: {
                    LogPill(text: label, isSelected: isSelected(item))
                }
                .buttonStyle(.plain)
            }
            if moreCount > 0 {
                Button(action: onMore) {
                    // Built by hand: a Label here showed only its icon inside FlowLayout.
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("\(moreCount) more")
                    }
                    .font(.subheadline)
                    .fixedSize()
                    .lineLimit(1)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.gray.opacity(0.18)))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Field names stay quiet so the chosen options are what you read first.
struct LogFieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Today and yesterday cover most logging, so they're one tap. Any other day opens a calendar.
struct LogDateField: View {
    @Binding var logDate: SimpleDate
    @State private var showDatePicker = false

    private enum Option: CaseIterable {
        case today, yesterday, other
    }

    var body: some View {
        let today = SimpleDate.today
        let yesterday = today.adding(days: -1)
        let isOtherDay = logDate != today && logDate != yesterday
        VStack(alignment: .leading, spacing: 8) {
            LogFieldLabel("Date")
            LogPillRow(
                items: Option.allCases,
                labels: ["Today", "Yesterday", isOtherDay ? logDate.formatted() : "Other day…"],
                isSelected: { option in
                    switch option {
                    case .today: return logDate == today
                    case .yesterday: return logDate == yesterday
                    case .other: return isOtherDay
                    }
                },
                onSelect: { option in
                    switch option {
                    case .today: logDate = today
                    case .yesterday: logDate = yesterday
                    case .other: showDatePicker = true
                    }
                }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .sheet(isPresented: $showDatePicker) {
            DatePicker(
                "Date",
                selection: .init(
                    get: { logDate.toDate() ?? .now },
                    set: { date in
                        if let day = SimpleDate(date: date) { logDate = day }
                        showDatePicker = false
                    }
                ),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

/// Always two rows: each snack sits under the meal it follows.
struct LogMealTimeField: View {
    @Binding var mealTime: MealTime

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LogFieldLabel("Meal")
                .underlined(mealTime == .none, color: .red, lineWidth: 1)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                pill(.breakfast)
                pill(.lunch)
                pill(.dinner)
                pill(.morningSnack, font: .footnote)
                pill(.afternoonSnack, font: .footnote)
                pill(.eveningSnack, font: .footnote)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func pill(_ option: MealTime, font: Font = .subheadline) -> some View {
        Button {
            mealTime = option
        } label: {
            LogPill(text: option.rawValue, isSelected: mealTime == option, font: font, fillsWidth: true)
        }
        .buttonStyle(.plain)
    }
}

/// The main action, pinned to the bottom. It reads back what will be logged ("Add to Lunch ·
/// 2 slices · 160 kcal · Today"), so a wrong meal or day is caught before saving. Uses the system
/// glass style so it matches the rest of the iOS 26 chrome.
struct LogActionButton: View {
    let title: String
    let detail: String?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .contentTransition(.numericText())
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .opacity(0.9)
                        .contentTransition(.numericText())
                }
            }
            .animation(.snappy, value: title)
            .animation(.snappy, value: detail)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            // Accent-tinted Liquid Glass, built by hand: the system .glassProminent style draws
            // its label in a pale tint that reads poorly on the accent.
            .glassEffect(
                .regular.tint(isEnabled ? Color.accentColor : Color.gray.opacity(0.4)).interactive(),
                in: .capsule
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .padding(.horizontal)
        .frame(maxWidth: .readableContentWidth)
        .padding(.bottom, 8)
    }
}
