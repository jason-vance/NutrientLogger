//
//  NutrientTrendDataProviderTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 6/24/26.
//

import XCTest
@testable import Nutrient_Logger

final class NutrientTrendDataProviderTests: XCTestCase {

    private var mockDatabase: RemoteDatabaseForScreenshots!
    private var provider: NutrientTrendDataProvider!

    override func setUp() {
        super.setUp()
        mockDatabase = RemoteDatabaseForScreenshots()
        provider = NutrientTrendDataProvider(remoteDatabase: mockDatabase)
    }

    private func makeConsumedFood(dateLogged: SimpleDate) -> ConsumedFood {
        ConsumedFood(
            fdcId: 1,
            name: "Honey",
            portionAmount: 1,
            portionGramWeight: 100,
            portionName: "cup",
            dateLogged: dateLogged,
            mealTime: .breakfast
        )
    }

    func testDateRangeSevenDays() {
        let today = SimpleDate(year: 2026, month: 6, day: 24)!
        let range = NutrientTrendDataProvider.dateRange(days: 7, endingOn: today)

        XCTAssertEqual(range.start, SimpleDate(year: 2026, month: 6, day: 18)!)
        XCTAssertEqual(range.end, today)
    }

    func testDateRangeThirtyDays() {
        let today = SimpleDate(year: 2026, month: 6, day: 24)!
        let range = NutrientTrendDataProvider.dateRange(days: 30, endingOn: today)

        XCTAssertEqual(range.start, SimpleDate(year: 2026, month: 5, day: 26)!)
        XCTAssertEqual(range.end, today)
    }

    func testDailyTotalsReturnsEntryForEachDay() {
        let start = SimpleDate(year: 2026, month: 6, day: 20)!
        let end = SimpleDate(year: 2026, month: 6, day: 24)!

        let totals = provider.dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            consumedFoods: [],
            startDate: start,
            endDate: end
        )

        XCTAssertEqual(totals.count, 5)
        XCTAssertEqual(totals[0].date, start)
        XCTAssertEqual(totals[4].date, end)
    }

    func testEmptyDaysHaveZeroAmount() {
        let start = SimpleDate(year: 2026, month: 6, day: 22)!
        let end = SimpleDate(year: 2026, month: 6, day: 24)!

        let totals = provider.dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            consumedFoods: [],
            startDate: start,
            endDate: end
        )

        for total in totals {
            XCTAssertEqual(total.amount, 0)
        }
    }

    func testEmptyDaysAreNotMarkedAsLogged() {
        let start = SimpleDate(year: 2026, month: 6, day: 22)!
        let end = SimpleDate(year: 2026, month: 6, day: 24)!

        let totals = provider.dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            consumedFoods: [],
            startDate: start,
            endDate: end
        )

        XCTAssertTrue(totals.allSatisfy { !$0.hasLoggedFoods })
    }

    func testOnlyDaysWithFoodsAreMarkedAsLogged() {
        let start = SimpleDate(year: 2026, month: 6, day: 22)!
        let loggedDate = SimpleDate(year: 2026, month: 6, day: 23)!
        let end = SimpleDate(year: 2026, month: 6, day: 24)!

        let totals = provider.dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            consumedFoods: [makeConsumedFood(dateLogged: loggedDate)],
            startDate: start,
            endDate: end
        )

        XCTAssertEqual(totals.count, 3)
        XCTAssertFalse(totals[0].hasLoggedFoods)
        XCTAssertTrue(totals[1].hasLoggedFoods)
        XCTAssertFalse(totals[2].hasLoggedFoods)
    }

    func testDayIsMarkedAsLoggedEvenWhenItHasNoneOfTheNutrient() {
        let day = SimpleDate(year: 2026, month: 6, day: 22)!

        let totals = provider.dailyTotals(
            for: "an-unknown-nutrient-number",
            consumedFoods: [makeConsumedFood(dateLogged: day)],
            startDate: day,
            endDate: day
        )

        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals[0].amount, 0)
        XCTAssertTrue(totals[0].hasLoggedFoods)
    }

    func testDateRangeCrossesMonthBoundary() {
        let today = SimpleDate(year: 2026, month: 7, day: 3)!
        let range = NutrientTrendDataProvider.dateRange(days: 7, endingOn: today)

        XCTAssertEqual(range.start, SimpleDate(year: 2026, month: 6, day: 27)!)
        XCTAssertEqual(range.end, today)
    }

    func testSingleDayRange() {
        let today = SimpleDate(year: 2026, month: 6, day: 24)!
        let range = NutrientTrendDataProvider.dateRange(days: 1, endingOn: today)

        XCTAssertEqual(range.start, today)
        XCTAssertEqual(range.end, today)

        let totals = provider.dailyTotals(
            for: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
            consumedFoods: [],
            startDate: range.start,
            endDate: range.end
        )

        XCTAssertEqual(totals.count, 1)
    }
}
