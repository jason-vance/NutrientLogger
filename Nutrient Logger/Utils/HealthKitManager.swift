//
//  HealthKitManager.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import Foundation
import HealthKit

class HealthKitManager {

    static let shared = HealthKitManager()

    static let healthSyncEnabledKey = "healthSyncEnabled"

    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isHealthSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.healthSyncEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.healthSyncEnabledKey) }
    }

    struct NutrientMapping {
        let hkType: HKQuantityTypeIdentifier
        let unit: HKUnit
        let unitName: String
    }

    // FDC nutrient number -> HealthKit type + unit
    static let nutrientMappings: [String: NutrientMapping] = [
        // Macros
        FdcNutrientGroupMapper.NutrientNumber_Energy_KCal: .init(hkType: .dietaryEnergyConsumed, unit: .kilocalorie(), unitName: "kcal"),
        FdcNutrientGroupMapper.NutrientNumber_Protein: .init(hkType: .dietaryProtein, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat: .init(hkType: .dietaryFatTotal, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference: .init(hkType: .dietaryCarbohydrates, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_Water: .init(hkType: .dietaryWater, unit: .literUnit(with: .milli), unitName: "g"),

        // Fat subtypes
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalSaturated: .init(hkType: .dietaryFatSaturated, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalMonounsaturated: .init(hkType: .dietaryFatMonounsaturated, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalPolyunsaturated: .init(hkType: .dietaryFatPolyunsaturated, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_Cholesterol: .init(hkType: .dietaryCholesterol, unit: .gramUnit(with: .milli), unitName: "mg"),

        // Carb subtypes
        FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary: .init(hkType: .dietaryFiber, unit: .gramUnit(with: .none), unitName: "g"),
        FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalIncludingNLEA: .init(hkType: .dietarySugar, unit: .gramUnit(with: .none), unitName: "g"),

        // Vitamins
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE: .init(hkType: .dietaryVitaminA, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminB6: .init(hkType: .dietaryVitaminB6, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12: .init(hkType: .dietaryVitaminB12, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid: .init(hkType: .dietaryVitaminC, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3: .init(hkType: .dietaryVitaminD, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol: .init(hkType: .dietaryVitaminE, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone: .init(hkType: .dietaryVitaminK, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Thiamin: .init(hkType: .dietaryThiamin, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Riboflavin: .init(hkType: .dietaryRiboflavin, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Niacin: .init(hkType: .dietaryNiacin, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid: .init(hkType: .dietaryPantothenicAcid, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Folate_DFE: .init(hkType: .dietaryFolate, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Biotin: .init(hkType: .dietaryBiotin, unit: .gramUnit(with: .micro), unitName: "μg"),

        // Minerals
        FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca: .init(hkType: .dietaryCalcium, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Iron_Fe: .init(hkType: .dietaryIron, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg: .init(hkType: .dietaryMagnesium, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn: .init(hkType: .dietaryManganese, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P: .init(hkType: .dietaryPhosphorus, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Potassium_K: .init(hkType: .dietaryPotassium, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Sodium_Na: .init(hkType: .dietarySodium, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn: .init(hkType: .dietaryZinc, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr: .init(hkType: .dietaryChromium, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Copper_Cu: .init(hkType: .dietaryCopper, unit: .gramUnit(with: .milli), unitName: "mg"),
        FdcNutrientGroupMapper.NutrientNumber_Iodine_I: .init(hkType: .dietaryIodine, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Molybdenum_Mo: .init(hkType: .dietaryMolybdenum, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Selenium_Se: .init(hkType: .dietarySelenium, unit: .gramUnit(with: .micro), unitName: "μg"),
        FdcNutrientGroupMapper.NutrientNumber_Chlorine_Cl: .init(hkType: .dietaryChloride, unit: .gramUnit(with: .milli), unitName: "mg"),

        // Other
        FdcNutrientGroupMapper.NutrientNumber_Caffeine: .init(hkType: .dietaryCaffeine, unit: .gramUnit(with: .milli), unitName: "mg"),
    ]

    private var writeTypes: Set<HKSampleType> {
        var types = Set(Self.nutrientMappings.values.map { HKQuantityType($0.hkType) })
        types.insert(HKQuantityType(.bodyMass))
        types.insert(HKQuantityType(.bodyFatPercentage))
        types.insert(HKQuantityType(.waistCircumference))
        return types
    }

    private var readTypes: Set<HKObjectType> {
        Set([
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.waistCircumference),
        ])
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func syncNutrients(_ nutrientTotals: [String: Double], date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Collect which HK types we wrote so we can clean up the rest
        var syncedTypes = Set<HKQuantityTypeIdentifier>()

        for (fdcNumber, amount) in nutrientTotals {
            guard let mapping = Self.nutrientMappings[fdcNumber], amount > 0 else { continue }

            let quantityType = HKQuantityType(mapping.hkType)
            await deleteExistingSamples(type: quantityType, start: startOfDay, end: endOfDay)
            syncedTypes.insert(mapping.hkType)

            let quantity = HKQuantity(unit: mapping.unit, doubleValue: amount)
            let sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: startOfDay,
                end: startOfDay
            )
            do {
                try await healthStore.save(sample)
            } catch {
                print("HealthKit save failed for \(mapping.hkType.rawValue): \(error.localizedDescription)")
            }
        }

        // Delete stale samples for nutrients that had no value today
        let allMappedTypes = Set(Self.nutrientMappings.values.map(\.hkType))
        for typeId in allMappedTypes where !syncedTypes.contains(typeId) {
            await deleteExistingSamples(type: HKQuantityType(typeId), start: startOfDay, end: endOfDay)
        }
    }

    private func deleteExistingSamples(type: HKQuantityType, start: Date, end: Date) async {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, sourcePredicate])

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            healthStore.deleteObjects(of: type, predicate: compound) { _, _, error in
                if let error {
                    print("HealthKit delete failed for \(type.identifier): \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }

    func saveWeight(_ kg: Double, date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }

        let quantityType = HKQuantityType(.bodyMass)
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        await deleteExistingSamples(type: quantityType, start: startOfDay, end: endOfDay)

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: startOfDay, end: startOfDay)
        do {
            try await healthStore.save(sample)
        } catch {
            print("HealthKit save weight failed: \(error.localizedDescription)")
        }
    }

    func saveBodyFat(_ percentage: Double, date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }

        let quantityType = HKQuantityType(.bodyFatPercentage)
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        await deleteExistingSamples(type: quantityType, start: startOfDay, end: endOfDay)

        let fraction = percentage / 100.0
        let quantity = HKQuantity(unit: .percent(), doubleValue: fraction)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: startOfDay, end: startOfDay)
        do {
            try await healthStore.save(sample)
        } catch {
            print("HealthKit save body fat failed: \(error.localizedDescription)")
        }
    }

    func deleteWeight(date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        await deleteExistingSamples(type: HKQuantityType(.bodyMass), start: startOfDay, end: endOfDay)
    }

    func deleteBodyFat(date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        await deleteExistingSamples(type: HKQuantityType(.bodyFatPercentage), start: startOfDay, end: endOfDay)
    }

    func fetchWeightHistory(limit: Int = 100) async -> [(date: Date, kg: Double)] {
        guard isAvailable else { return [] }

        let weightType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    print("HealthKit weight history fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                let results = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.startDate, kg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }

    func fetchBodyFatHistory(limit: Int = 100) async -> [(date: Date, percentage: Double)] {
        guard isAvailable else { return [] }

        let bfType = HKQuantityType(.bodyFatPercentage)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bfType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    print("HealthKit body fat history fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                let results = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.startDate, percentage: sample.quantity.doubleValue(for: .percent()) * 100.0)
                } ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }

    func saveWaist(_ cm: Double, date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }
        let quantityType = HKQuantityType(.waistCircumference)
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        await deleteExistingSamples(type: quantityType, start: startOfDay, end: endOfDay)
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: cm)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: startOfDay, end: startOfDay)
        do {
            try await healthStore.save(sample)
        } catch {
            print("HealthKit save waist failed: \(error.localizedDescription)")
        }
    }

    func deleteWaist(date: Date) async {
        guard isAvailable, isHealthSyncEnabled else { return }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        await deleteExistingSamples(type: HKQuantityType(.waistCircumference), start: startOfDay, end: endOfDay)
    }

    func fetchWaistHistory(limit: Int = 100) async -> [(date: Date, cm: Double)] {
        guard isAvailable else { return [] }
        let waistType = HKQuantityType(.waistCircumference)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: waistType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    print("HealthKit waist history fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                let results = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.startDate, cm: sample.quantity.doubleValue(for: .meterUnit(with: .centi)))
                } ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }

    func fetchLatestWeight() async -> Double? {
        guard isAvailable else { return nil }

        let weightType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    print("HealthKit weight fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let lbs = kg * 2.20462
                continuation.resume(returning: lbs)
            }
            healthStore.execute(query)
        }
    }
}
