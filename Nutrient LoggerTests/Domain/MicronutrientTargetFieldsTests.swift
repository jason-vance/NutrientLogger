//
//  MicronutrientTargetFieldsTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 8/24/26.
//

import Foundation
import Testing

struct MicronutrientTargetFieldsTests {

    private var mineralIds: [String] { MicronutrientTargetFields.minerals.map(\.fdcNumber) }

    @Test func sodiumIsOfferedAsAConfigurableMineral() {
        #expect(mineralIds.contains(FdcNutrientGroupMapper.NutrientNumber_Sodium_Na))
    }

    @Test func sodiumSitsNextToPotassium() {
        let sodium = mineralIds.firstIndex(of: FdcNutrientGroupMapper.NutrientNumber_Sodium_Na)
        let potassium = mineralIds.firstIndex(of: FdcNutrientGroupMapper.NutrientNumber_Potassium_K)

        #expect(sodium != nil)
        #expect(potassium != nil)
        #expect(sodium! == potassium! + 1)
    }

    @Test func sodiumIsListedOnlyOnce() {
        let sodiumCount = mineralIds.filter { $0 == FdcNutrientGroupMapper.NutrientNumber_Sodium_Na }.count

        #expect(sodiumCount == 1)
    }

    @Test func sodiumKeepsItsLabelUnitFromTheSharedFieldList() {
        let sodium = MicronutrientTargetFields.minerals.first {
            $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Sodium_Na
        }

        #expect(sodium?.name == "Sodium")
        #expect(sodium?.unit == "mg")
    }

    @Test func everyOtherMineralIsStillOffered() {
        let expected = CustomFood.formFields
            .filter { $0.group == "Minerals" }
            .map(\.fdcNumber)

        #expect(expected.allSatisfy { mineralIds.contains($0) })
        #expect(mineralIds.count == expected.count + 1)
    }

    @Test func theMineralGroupOrderIsOtherwiseUnchanged() {
        let withoutSodium = mineralIds.filter { $0 != FdcNutrientGroupMapper.NutrientNumber_Sodium_Na }
        let original = CustomFood.formFields
            .filter { $0.group == "Minerals" }
            .map(\.fdcNumber)

        #expect(withoutSodium == original)
    }

    @Test func fieldsForGroupRoutesMineralsThroughTheAugmentedList() {
        let fields = MicronutrientTargetFields.fields(forGroup: "Minerals")

        #expect(fields.map(\.fdcNumber) == mineralIds)
    }

    @Test func otherGroupsAreLeftExactlyAsTheSharedListHasThem() {
        for group in ["Vitamins", "Fatty Acids", "Amino Acids"] {
            let fields = MicronutrientTargetFields.fields(forGroup: group).map(\.fdcNumber)
            let expected = CustomFood.formFields.filter { $0.group == group }.map(\.fdcNumber)

            #expect(fields == expected)
        }
    }

    @Test func sodiumIsNotDuplicatedIntoTheMacrosSection() {
        // It stays under Macros in the shared list, which the custom food form and barcode
        // review still render from.
        let macros = MicronutrientTargetFields.fields(forGroup: "Macros").map(\.fdcNumber)

        #expect(macros.contains(FdcNutrientGroupMapper.NutrientNumber_Sodium_Na))
    }
}
