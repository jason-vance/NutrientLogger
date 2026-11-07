//
//  EverydayFoodNamesTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct EverydayFoodNamesTests {

    @Test func toastLeadsWithToastedBread() {
        #expect(EverydayFoodNames.leadingDescriptions(for: "toast") == [
            "Bread, white, toasted",
            "Bread, whole wheat, toasted",
        ])
    }

    @Test func matchesTheWayASearchIsTyped() {
        #expect(EverydayFoodNames.leadingDescriptions(for: "Toast") == EverydayFoodNames.leadingDescriptions(for: "toast"))
        #expect(EverydayFoodNames.leadingDescriptions(for: "2 slices toast") == EverydayFoodNames.leadingDescriptions(for: "toast"))
        #expect(EverydayFoodNames.leadingDescriptions(for: "Mac & Cheese") == ["Macaroni or noodles with cheese"])
    }

    @Test func onlyTheWholeSearchMatches() {
        #expect(EverydayFoodNames.leadingDescriptions(for: "french toast").isEmpty)
        #expect(EverydayFoodNames.leadingDescriptions(for: "teriyaki").isEmpty)
    }

    @Test func leadsComeFirstAndEachFoodShowsOnce() {
        let whiteToast = FdcSearchableFood(fdcId: 1, description: "Bread, white, toasted", rank: 0)
        let frenchToast = FdcSearchableFood(fdcId: 2, description: "French toast, NFS", rank: 0)
        let whiteToastOtherDataset = FdcSearchableFood(fdcId: 3, description: "Bread, white, toasted", rank: 0)

        let merged = EverydayFoodNames.withLeads([whiteToast], before: [frenchToast, whiteToast, whiteToastOtherDataset])
        #expect(merged.map(\.fdcId) == [1, 2])
    }
}
