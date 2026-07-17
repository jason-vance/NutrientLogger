//
//  NutrientBalanceSettingsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/17/26.
//

import Foundation
import Testing

struct NutrientBalanceSettingsTests {

    @Test func defaultsIncludeAllFiveTierBalances() {
        let ids = NutrientBalanceDefaults.all.map(\.id)
        #expect(ids.contains(NutrientBalanceDefaults.sodiumPotassiumId))
        #expect(ids.contains(NutrientBalanceDefaults.zincCopperId))
        #expect(ids.contains(NutrientBalanceDefaults.omega6Omega3Id))
        #expect(ids.contains(NutrientBalanceDefaults.calciumPhosphorusId))
        #expect(ids.contains(NutrientBalanceDefaults.calciumMagnesiumId))
    }

    @Test func effectiveRatiosHidesDisabledBuiltIns() {
        let hidden = NutrientBalanceSettings.encodeHidden([NutrientBalanceDefaults.zincCopperId])
        let ratios = NutrientBalanceSettings.effectiveRatios(hiddenRaw: hidden, customRaw: "")
        #expect(!ratios.contains { $0.id == NutrientBalanceDefaults.zincCopperId })
        #expect(ratios.contains { $0.id == NutrientBalanceDefaults.sodiumPotassiumId })
    }

    @Test func customRatiosRoundTripThroughEncoding() {
        let custom = NutrientRatio(
            id: "custom-1",
            name: "Iron : Zinc",
            numeratorLabel: "Iron",
            denominatorLabel: "Zinc",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Iron_Fe],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn],
            healthyMax: 2.0,
            healthyMin: nil,
            explanation: "",
            isBuiltIn: false
        )
        let encoded = NutrientBalanceSettings.encode(customRatios: [custom])
        let decoded = NutrientBalanceSettings.customRatios(from: encoded)
        #expect(decoded == [custom])
    }

    @Test func effectiveRatiosAppendsCustomAndRespectsHidden() {
        let custom = NutrientRatio(
            id: "custom-1",
            name: "Iron : Zinc",
            numeratorLabel: "Iron",
            denominatorLabel: "Zinc",
            numeratorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Iron_Fe],
            denominatorNutrientIds: [FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn],
            healthyMax: 2.0,
            healthyMin: nil,
            explanation: "",
            isBuiltIn: false
        )
        let customRaw = NutrientBalanceSettings.encode(customRatios: [custom])

        let visible = NutrientBalanceSettings.effectiveRatios(hiddenRaw: "", customRaw: customRaw)
        #expect(visible.contains { $0.id == "custom-1" })

        let hidden = NutrientBalanceSettings.encodeHidden(["custom-1"])
        let filtered = NutrientBalanceSettings.effectiveRatios(hiddenRaw: hidden, customRaw: customRaw)
        #expect(!filtered.contains { $0.id == "custom-1" })
    }

    @Test func emptyRawStringsYieldDefaultsOnly() {
        let ratios = NutrientBalanceSettings.effectiveRatios(hiddenRaw: "", customRaw: "")
        #expect(ratios.count == NutrientBalanceDefaults.all.count)
    }
}
