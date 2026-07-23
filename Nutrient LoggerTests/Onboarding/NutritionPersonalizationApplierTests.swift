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
        .lipids: [
            FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
            FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
            FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA,
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

    // MARK: - replacingExisting (onboarding re-selection)

    @Test func replacingExistingOverwritesPriorSelection() {
        let defaults = makeDefaults()
        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)

        // First selection promotes zinc/selenium into minerals...
        applier.apply(diet: .balanced, concern: .immunity, replacingExisting: true)
        // ...then the user changes to a heart-health focus (potassium/magnesium/sodium first).
        applier.apply(diet: .balanced, concern: .heartHealth, replacingExisting: true)

        let minerals = defaults.string(forKey: CustomizableNutrientGroup.minerals.orderStorageKey)?
            .split(separator: ",").map(String.init)
        #expect(minerals?.first == FdcNutrientGroupMapper.NutrientNumber_Potassium_K)
        #expect(minerals?.contains(FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn) == true) // still present, just not pinned
        #expect(minerals?.prefix(3).contains(FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn) == false)
    }

    @Test func replacingExistingResetsGroupsTheNewSelectionNoLongerPromotes() {
        let defaults = makeDefaults()
        let applier = NutritionPersonalizationApplier(defaults: defaults, defaultOrders: defaultOrders)

        // Heart health promotes lipids (omega-3s)...
        applier.apply(diet: .balanced, concern: .heartHealth, replacingExisting: true)
        #expect(defaults.string(forKey: CustomizableNutrientGroup.lipids.orderStorageKey) != nil)

        // ...switching to immunity (no lipids) must clear the lipids order + visible count.
        applier.apply(diet: .balanced, concern: .immunity, replacingExisting: true)
        #expect(defaults.string(forKey: CustomizableNutrientGroup.lipids.orderStorageKey) == nil)
        #expect(defaults.object(forKey: CustomizableNutrientGroup.lipids.visibleCountStorageKey) == nil)
    }
}
