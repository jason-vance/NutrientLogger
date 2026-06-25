//
//  WeightEntrySheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import SwiftData

struct WeightEntrySheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Inject private var engagementAnalytics: EngagementAnalytics

    @AppStorage("preferredWeightUnit") private var preferredUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage(HealthKitManager.healthSyncEnabledKey) private var healthSyncEnabled = false

    @State private var date: Date = .now
    @State private var weightText: String = ""
    @State private var bodyFatText: String = ""

    let existingWeight: WeightEntry?
    let existingBodyFat: BodyFatEntry?

    private var preferredUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredUnitRaw) ?? .lbs
    }

    init(existingWeight: WeightEntry? = nil, existingBodyFat: BodyFatEntry? = nil) {
        self.existingWeight = existingWeight
        self.existingBodyFat = existingBodyFat
    }

    private var hasValidWeight: Bool {
        guard !weightText.isEmpty else { return false }
        guard let w = Double(weightText), w > 0 else { return false }
        return true
    }

    private var hasValidBodyFat: Bool {
        guard !bodyFatText.isEmpty else { return false }
        guard let bf = Double(bodyFatText), bf > 0, bf < 100 else { return false }
        return true
    }

    private var canSave: Bool {
        let hasAtLeastOne = hasValidWeight || hasValidBodyFat
        let weightOk = weightText.isEmpty || hasValidWeight
        let bodyFatOk = bodyFatText.isEmpty || hasValidBodyFat
        return hasAtLeastOne && weightOk && bodyFatOk
    }

    private func populateFromExisting() {
        if let existing = existingWeight {
            date = existing.date.toDate() ?? .now
            let displayWeight = preferredUnit.fromKg(existing.weightKg)
            weightText = displayWeight.formatted(maxDigits: 1)
        }
        if let existing = existingBodyFat {
            if existingWeight == nil {
                date = existing.date.toDate() ?? .now
            }
            bodyFatText = existing.percentage.formatted(maxDigits: 1)
        }
    }

    private func save() {
        guard let simpleDate = SimpleDate(date: date) else { return }

        if hasValidWeight, let weightValue = Double(weightText) {
            let weightKg = preferredUnit.toKg(weightValue)

            let weightDescriptor = FetchDescriptor<WeightEntry>(
                predicate: #Predicate { $0.date == simpleDate }
            )
            if let existing = try? modelContext.fetch(weightDescriptor).first {
                existing.weightKg = weightKg
            } else {
                modelContext.insert(WeightEntry(date: simpleDate, weightKg: weightKg))
            }

            if healthSyncEnabled {
                Task { await HealthKitManager.shared.saveWeight(weightKg, date: date) }
            }
        }

        if hasValidBodyFat, let bodyFatValue = Double(bodyFatText) {
            let bfDescriptor = FetchDescriptor<BodyFatEntry>(
                predicate: #Predicate { $0.date == simpleDate }
            )
            if let existing = try? modelContext.fetch(bfDescriptor).first {
                existing.percentage = bodyFatValue
            } else {
                modelContext.insert(BodyFatEntry(date: simpleDate, percentage: bodyFatValue))
            }

            if healthSyncEnabled {
                Task { await HealthKitManager.shared.saveBodyFat(bodyFatValue, date: date) }
            }
        }

        try? modelContext.save()
        engagementAnalytics.weightLogged()
        dismiss()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .listRowDefaultModifiers()
                }

                Section {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("--", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .bold()
                            .frame(maxWidth: 100)
                        Text(preferredUnit.label)
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                    }
                    .listRowDefaultModifiers()

                    HStack {
                        Text("Body Fat")
                        Spacer()
                        TextField("--", text: $bodyFatText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .bold()
                            .frame(maxWidth: 100)
                        Text("%")
                            .fontWeight(.light)
                            .foregroundStyle(.secondary)
                    }
                    .listRowDefaultModifiers()
                }
            }
            .listDefaultModifiers()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Toolbar() }
            .onAppear { populateFromExisting() }
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { save() }
                .bold()
                .disabled(!canSave)
        }
    }
}

#Preview {
    WeightEntrySheet()
}
