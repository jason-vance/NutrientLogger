//
//  LoggedThisSearchBar.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/4/26.
//

import SwiftUI
import SwiftData

/// A bar at the bottom of search that counts the foods logged since search opened. Tapping it
/// lists them, so the user can check nothing was missed and fix a wrong meal or amount in place.
struct LoggedThisSearchBar: View {

    @Query private var foods: [ConsumedFood]

    @State private var showList: Bool = false

    @Inject private var engagementAnalytics: EngagementAnalytics

    init(since start: Date) {
        _foods = Query(
            filter: #Predicate<ConsumedFood> { $0.created >= start },
            sort: \.created,
            order: .forward
        )
    }

    var body: some View {
        Group {
            if !foods.isEmpty {
                Button {
                    engagementAnalytics.searchLogOpened(foodCount: foods.count)
                    showList = true
                } label: {
                    BarLabel()
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: foods.count)
        .sheet(isPresented: $showList) {
            LoggedThisSearchList(foods: foods)
                .environmentObject(DataController.shared)
                .environmentObject(CustomFoodDatabase.shared)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder private func BarLabel() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(foods.count) logged")
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
                Text(SearchSessionLog.namesSummary(newestFirst: foods.reversed().map(\.name)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Text("Review")
                Image(systemName: "chevron.up")
            }
            .font(.subheadline)
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

/// Everything logged since search opened, by meal. Tap to fix, swipe to delete.
private struct LoggedThisSearchList: View {

    let foods: [ConsumedFood]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataController: DataController

    @State private var foodBeingEdited: ConsumedFood?

    @Inject private var engagementAnalytics: EngagementAnalytics

    private var groups: [SearchSessionLog.Group<ConsumedFood>] {
        SearchSessionLog.groups(foods, date: \.dateLogged, mealTime: \.mealTime)
    }

    var body: some View {
        NavigationStack {
            List {
                if foods.isEmpty {
                    ContentUnavailableView(
                        "Nothing Logged",
                        systemImage: "tray",
                        description: Text("Foods you log in this search show up here.")
                    )
                    .listRowBackground(Color.clear)
                }
                ForEach(groups) { group in
                    Section(SearchSessionLog.title(
                        date: group.date,
                        mealTime: group.mealTime,
                        today: .today,
                        dayName: group.date.formatted()
                    )) {
                        ForEach(group.items) { food in
                            FoodRow(food)
                        }
                    }
                }
            }
            .animation(.snappy, value: foods)
            .navigationTitle("Logged This Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationDestination(item: $foodBeingEdited) { food in
                FoodDetailsView(
                    mode: .loggedFood(food: food),
                    onFoodSaved: { foodItem, portion in
                        food.portionAmount = portion.amount
                        food.portionGramWeight = portion.gramWeight
                        food.portionName = portion.name
                        food.dateLogged = foodItem.dateLogged ?? food.dateLogged
                        food.mealTime = foodItem.mealTime ?? food.mealTime
                        engagementAnalytics.searchLogFoodChanged(action: "edited")
                        dataController.updateDailySummary()
                    }
                )
            }
        }
    }

    @ViewBuilder private func FoodRow(_ food: ConsumedFood) -> some View {
        Button {
            foodBeingEdited = food
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    Text(LogPortionDefaults.summary(amount: food.portionAmount, portionName: food.portionName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                modelContext.delete(food)
                engagementAnalytics.searchLogFoodChanged(action: "deleted")
                dataController.updateDailySummary()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
