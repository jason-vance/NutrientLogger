//
//  NutritionPersonalizationPlanTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation
import Testing

struct NutritionPersonalizationPlanTests {

    // Small stand-in whitelists so the tests don't depend on the real dashboard sections.
    // Values are the real FdcNutrientGroupMapper IDs the presets reference.
    private let defaultOrders: [CustomizableNutrientGroup: [String]] = [
        .vitamins: [
            FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
            FdcNutrientGroupMapper.NutrientNumber_VitaminB6,
            FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
            FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
            FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
            FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
            FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol,
            FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone,
        ],
        .minerals: [
            FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
            FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
            FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn,
            FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P,
            FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
            FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
            FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
            FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
        ],
        .lipids: [
            FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
            FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
            FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA,
        ],
        .aminoAcids: [
            FdcNutrientGroupMapper.NutrientNumber_Leucine,
            FdcNutrientGroupMapper.NutrientNumber_Isoleucine,
            FdcNutrientGroupMapper.NutrientNumber_Valine,
        ],
    ]

    // MARK: - Defaults

    @Test func defaultAnswersProduceEmptyPlan() {
        let plan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .generalHealth,
            defaultOrders: defaultOrders
        )

        #expect(plan.isEmpty)
        #expect(plan.orderByGroup.isEmpty)
        #expect(plan.visibleCountByGroup.isEmpty)
    }

    @Test func groupsWithNoPromotedNutrientsAreLeftUntouched() {
        // Immunity touches only vitamins + minerals, so lipids/amino acids must be absent.
        let plan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .immunity,
            defaultOrders: defaultOrders
        )

        #expect(plan.orderByGroup[.lipids] == nil)
        #expect(plan.orderByGroup[.aminoAcids] == nil)
        #expect(plan.visibleCountByGroup[.lipids] == nil)
    }

    // MARK: - Promotion & ordering

    @Test func promotedNutrientsMoveToFrontThenDefaultsFollow() {
        let plan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .immunity,
            defaultOrders: defaultOrders
        )

        // Immunity vitamins: C, D, A (concern order).
        let vitamins = plan.orderByGroup[.vitamins]!
        #expect(Array(vitamins.prefix(3)) == [
            FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
            FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
            FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
        ])
        // No nutrient dropped or duplicated — same set as the default whitelist.
        #expect(Set(vitamins) == Set(defaultOrders[.vitamins]!))
        #expect(vitamins.count == defaultOrders[.vitamins]!.count)
    }

    @Test func visibleCountMatchesPromotedCountWhenAboveDefault() {
        // Keto promotes 3 minerals, immunity adds zinc + selenium ⇒ 5 unique minerals.
        let plan = NutritionPersonalizationPlan.make(
            diet: .ketoLowCarb,
            concern: .immunity,
            defaultOrders: defaultOrders
        )

        #expect(plan.visibleCountByGroup[.minerals] == 5)
        #expect(Array(plan.orderByGroup[.minerals]!.prefix(5)) == [
            // concern first: zinc, selenium; then diet: magnesium, potassium, sodium
            FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
            FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
            FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
            FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
            FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
        ])
    }

    @Test func visibleCountNeverDropsBelowDefault() {
        // Pescatarian promotes a single vitamin (D) ⇒ count clamps up to the default of 3.
        let plan = NutritionPersonalizationPlan.make(
            diet: .pescatarian,
            concern: .generalHealth,
            defaultOrders: defaultOrders
        )

        #expect(plan.visibleCountByGroup[.vitamins] == 3)
    }

    @Test func overlappingNutrientsAreDeduplicated() {
        // Plant-based minerals: Iron, Zinc, Calcium. Energy minerals: Iron, Magnesium.
        // Union should be 4 (Iron counted once).
        let plan = NutritionPersonalizationPlan.make(
            diet: .plantBased,
            concern: .energy,
            defaultOrders: defaultOrders
        )

        let minerals = plan.orderByGroup[.minerals]!
        #expect(plan.visibleCountByGroup[.minerals] == 4)
        #expect(Array(minerals.prefix(4)) == [
            FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,      // concern + diet, deduped
            FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg, // concern
            FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,      // diet
            FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,   // diet
        ])
    }

    @Test func promotedNutrientsMissingFromDefaultsAreIgnored() {
        // A whitelist that lacks selenium: immunity's selenium should be dropped, count reflects it.
        var trimmed = defaultOrders
        trimmed[.minerals] = trimmed[.minerals]!.filter {
            $0 != FdcNutrientGroupMapper.NutrientNumber_Selenium_Se
        }

        let plan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .immunity,
            defaultOrders: trimmed
        )

        let minerals = plan.orderByGroup[.minerals]!
        #expect(!minerals.contains(FdcNutrientGroupMapper.NutrientNumber_Selenium_Se))
        // Only zinc promoted from minerals ⇒ clamps to default 3.
        #expect(plan.visibleCountByGroup[.minerals] == 3)
    }

    @Test func lipidsAndAminoAcidsCanBePromoted() {
        // Heart health promotes lipids; muscle promotes amino acids.
        let plan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .heartHealth,
            defaultOrders: defaultOrders
        )
        #expect(plan.visibleCountByGroup[.lipids] == 3)
        #expect(Array(plan.orderByGroup[.lipids]!.prefix(1)) == [
            FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
        ])

        let musclePlan = NutritionPersonalizationPlan.make(
            diet: .balanced,
            concern: .muscleAthletic,
            defaultOrders: defaultOrders
        )
        #expect(musclePlan.orderByGroup[.aminoAcids]!.first == FdcNutrientGroupMapper.NutrientNumber_Leucine)
    }
}
