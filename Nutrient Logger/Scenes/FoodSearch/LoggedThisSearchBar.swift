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
    @State private var groupBeingSaved: SearchSessionLog.Group<ConsumedFood>?
    @State private var mealName: String = ""
    @State private var savedGroupIds: Set<String> = []

    @Inject private var engagementAnalytics: EngagementAnalytics
    @Inject private var mealsAnalytics: UserMealsAnalytics

    /// Saves a group's foods and portions as a reusable meal, found in search next time.
    private func saveAsMeal(_ group: SearchSessionLog.Group<ConsumedFood>, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let meal = Meal(name: trimmed.isEmpty ? SearchSessionLog.suggestedMealName(for: group.items.map(\.name)) : trimmed)
        meal.addFoods(group.items.map {
            Meal.FoodWithPortion(
                foodFdcId: $0.fdcId,
                foodName: $0.name,
                portionAmount: $0.portionAmount,
                portionGramWeight: $0.portionGramWeight,
                portionName: $0.portionName
            )
        })
        modelContext.insert(meal)
        savedGroupIds.insert(group.id)
        mealsAnalytics.mealCreated()
        engagementAnalytics.searchLogFoodChanged(action: "saved_as_meal")
    }

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
                    Section {
                        ForEach(group.items) { food in
                            FoodRow(food)
                        }
                    } header: {
                        GroupHeader(group)
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
            .alert("Save as Meal", isPresented: .init(
                get: { groupBeingSaved != nil },
                set: { if !$0 { groupBeingSaved = nil } }
            )) {
                TextField("Meal name", text: $mealName)
                Button("Save") {
                    if let group = groupBeingSaved { saveAsMeal(group, name: mealName) }
                    groupBeingSaved = nil
                }
                Button("Cancel", role: .cancel) { groupBeingSaved = nil }
            } message: {
                Text("Next time, find it in search and log all of these in one tap.")
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

    @ViewBuilder private func GroupHeader(_ group: SearchSessionLog.Group<ConsumedFood>) -> some View {
        HStack {
            Text(SearchSessionLog.title(
                date: group.date,
                mealTime: group.mealTime,
                today: .today,
                dayName: group.date.formatted()
            ))
            Spacer()
            if group.items.count >= 2 {
                if savedGroupIds.contains(group.id) {
                    Label("Saved", systemImage: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        mealName = SearchSessionLog.suggestedMealName(for: group.items.map(\.name))
                        groupBeingSaved = group
                    } label: {
                        Label("Save as Meal", systemImage: "square.and.arrow.down")
                            .font(.caption.bold())
                    }
                }
            }
        }
        .textCase(nil)
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
