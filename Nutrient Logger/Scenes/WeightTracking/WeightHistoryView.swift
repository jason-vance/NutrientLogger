//
//  WeightHistoryView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import SwiftData

struct WeightHistoryView: View {

    @Environment(\.modelContext) private var modelContext

    @Inject private var engagementAnalytics: EngagementAnalytics

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @Query(sort: \WeightEntry.date, order: .reverse) private var allWeightEntries: [WeightEntry]
    @Query(sort: \BodyFatEntry.date, order: .reverse) private var allBodyFatEntries: [BodyFatEntry]

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var allEntryDates: [SimpleDate] {
        let weightDates = Set(allWeightEntries.map(\.date))
        let bfDates = Set(allBodyFatEntries.map(\.date))
        return weightDates.union(bfDates).sorted(by: >)
    }

    private func deleteWeightEntry(_ entry: WeightEntry) {
        let date = entry.date
        modelContext.delete(entry)
        try? modelContext.save()

        if healthSyncEnabled, let entryDate = date.toDate() {
            Task { await HealthKitManager.shared.deleteWeight(date: entryDate) }
        }

        engagementAnalytics.weightDeleted()
    }

    private func deleteBodyFatEntry(_ entry: BodyFatEntry) {
        let date = entry.date
        modelContext.delete(entry)
        try? modelContext.save()

        if healthSyncEnabled, let entryDate = date.toDate() {
            Task { await HealthKitManager.shared.deleteBodyFat(date: entryDate) }
        }
    }

    var body: some View {
        List {
            if allEntryDates.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "scalemass",
                    description: Text("Log your weight or body fat to see your history here.")
                )
                .listRowDefaultModifiers()
            } else {
                ForEach(allEntryDates, id: \.self) { date in
                    let weight = allWeightEntries.first { $0.date == date }
                    let bodyFat = allBodyFatEntries.first { $0.date == date }
                    HStack {
                        Text(date.formatted())
                        Spacer()
                        VStack(alignment: .trailing) {
                            if let w = weight {
                                Text("\(preferredUnit.fromKg(w.weightKg).formatted(maxDigits: 1)) \(preferredUnit.label)")
                                    .bold()
                            }
                            if let bf = bodyFat {
                                Text("\(bf.percentage.formatted(maxDigits: 1))% body fat")
                                    .font(weight != nil ? .caption : .body)
                                    .fontWeight(weight != nil ? .regular : .bold)
                                    .foregroundStyle(weight != nil ? .secondary : .primary)
                            }
                        }
                    }
                    .listRowDefaultModifiers()
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let bf = bodyFat { deleteBodyFatEntry(bf) }
                            if let w = weight { deleteWeightEntry(w) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listDefaultModifiers()
        .navigationTitle("History")
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        WeightHistoryView()
    }
}
