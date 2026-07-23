//
//  NutritionPersonalizationApplierTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation
import Testing

struct NutritionPersonalizationApplierTests {

    private let defaultOrders: [CustomizableNutrientGroup: [String]] = [
        .vitamins: [
            FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
            FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
            FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
            FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
        ],
        .minerals: [
            FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
            FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
            FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
            FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
            FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
        ],
    ]

    private func makeDefaults() -> UserDefaults {
        let suite = "applier-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func writesOrderAndVisibleCountForPromotedGroups() {
        let defaults = makeDefaults()
        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)

        applier.apply(diet: .balanced, concern: .immunity)

        let vitaminsOrder = defaults.string(forKey: CustomizableNutrientGroup.vitamins.orderStorageKey)
        #expect(vitaminsOrder?.split(separator: ",").prefix(2).map(String.init) == [
            FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
            FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
        ])
        // Immunity promotes 2 minerals (zinc, selenium) ⇒ clamps up to the default of 3.
        #expect(defaults.integer(forKey: CustomizableNutrientGroup.minerals.visibleCountStorageKey) == 3)
    }

    @Test func leavesUntouchedGroupsUnwritten() {
        let defaults = makeDefaults()
        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)

        applier.apply(diet: .balanced, concern: .immunity)

        // Lipids/amino acids aren't promoted by immunity ⇒ keys never written.
        #expect(defaults.string(forKey: CustomizableNutrientGroup.lipids.orderStorageKey) == nil)
        #expect(defaults.object(forKey: CustomizableNutrientGroup.lipids.visibleCountStorageKey) == nil)
    }

    @Test func doesNotClobberExistingCustomization() {
        let defaults = makeDefaults()
        let existing = "already,customized"
        defaults.set(existing, forKey: CustomizableNutrientGroup.vitamins.orderStorageKey)

        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)
        applier.apply(diet: .balanced, concern: .immunity)

        // Vitamins already customized → untouched; minerals (untouched before) → written.
        #expect(defaults.string(forKey: CustomizableNutrientGroup.vitamins.orderStorageKey) == existing)
        #expect(defaults.string(forKey: CustomizableNutrientGroup.minerals.orderStorageKey) != nil)
    }

    @Test func defaultAnswersWriteNothing() {
        let defaults = makeDefaults()
        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)

        applier.apply(diet: .balanced, concern: .generalHealth)

        for group in CustomizableNutrientGroup.allCases {
            #expect(defaults.string(forKey: group.orderStorageKey) == nil)
        }
    }
}
