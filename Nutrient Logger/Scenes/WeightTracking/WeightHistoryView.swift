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
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @Query(sort: \WeightEntry.date, order: .reverse) private var allWeightEntries: [WeightEntry]
    @Query(sort: \BodyFatEntry.date, order: .reverse) private var allBodyFatEntries: [BodyFatEntry]
    @Query(sort: \WaistEntry.date, order: .reverse) private var allWaistEntries: [WaistEntry]

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    private var preferredWaistUnit: WaistUnit {
        (HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn).waistUnit
    }

    private var allEntryDates: [SimpleDate] {
        let weightDates = Set(allWeightEntries.map(\.date))
        let bfDates = Set(allBodyFatEntries.map(\.date))
        let waistDates = Set(allWaistEntries.map(\.date))
        return weightDates.union(bfDates).union(waistDates).sorted(by: >)
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

    private func deleteWaistEntry(_ entry: WaistEntry) {
        let date = entry.date
        modelContext.delete(entry)
        try? modelContext.save()
        if healthSyncEnabled, let entryDate = date.toDate() {
            Task { await HealthKitManager.shared.deleteWaist(date: entryDate) }
        }
    }

    var body: some View {
        List {
            if allEntryDates.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "scalemass",
                    description: Text("Log your body metrics to see your history here.")
                )
                .listRowDefaultModifiers()
            } else {
                ForEach(allEntryDates, id: \.self) { date in
                    let weight = allWeightEntries.first { $0.date == date }
                    let bodyFat = allBodyFatEntries.first { $0.date == date }
                    let waist = allWaistEntries.first { $0.date == date }
                    let isPrimary = weight != nil
                    HStack {
                        Text(date.formatted())
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let w = weight {
                                Text("\(preferredUnit.fromKg(w.weightKg).formatted(maxDigits: 1)) \(preferredUnit.label)")
                                    .bold()
                            }
                            if let bf = bodyFat {
                                Text("\(bf.percentage.formatted(maxDigits: 1))% body fat")
                                    .font(isPrimary ? .caption : .body)
                                    .fontWeight(isPrimary ? .regular : .bold)
                                    .foregroundStyle(isPrimary ? .secondary : .primary)
                            }
                            if let wt = waist {
                                Text("\(preferredWaistUnit.fromCm(wt.circumferenceCm).formatted(maxDigits: 1)) \(preferredWaistUnit.label) waist")
                                    .font(isPrimary ? .caption : .body)
                                    .fontWeight(isPrimary ? .regular : .bold)
                                    .foregroundStyle(isPrimary ? .secondary : .primary)
                            }
                        }
                    }
                    .listRowDefaultModifiers()
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let w = weight { deleteWeightEntry(w) }
                            if let bf = bodyFat { deleteBodyFatEntry(bf) }
                            if let wt = waist { deleteWaistEntry(wt) }
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
