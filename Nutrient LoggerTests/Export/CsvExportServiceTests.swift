//
//  CsvExportServiceTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 7/7/26.
//

import XCTest
@testable import Nutrient_Logger

final class CsvExportServiceTests: XCTestCase {

    private var mockDatabase: MockRemoteDatabase!
    private var service: CsvExportService!

    override func setUp() {
        super.setUp()
        mockDatabase = MockRemoteDatabase()
        service = CsvExportService(remoteDatabase: mockDatabase)
    }

    private func makeConsumedFood(
        fdcId: Int = 1,
        name: String = "Honey",
        dateLogged: SimpleDate = SimpleDate(year: 2026, month: 6, day: 1)!,
        mealTime: MealTime = .breakfast
    ) -> ConsumedFood {
        ConsumedFood(
            fdcId: fdcId,
            name: name,
            portionAmount: 1,
            portionGramWeight: 100,
            portionName: "cup",
            dateLogged: dateLogged,
            mealTime: mealTime
        )
    }

    func testEmptyConsumedFoodsProducesHeaderOnly() {
        let csv = service.generateCsv(consumedFoods: [])
        let lines = csv.components(separatedBy: "\r\n")

        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].hasPrefix("Date,Meal,Food,Amount,Portion,Grams"))
    }

    func testRowIncludesFoodAndNutrientData() {
        mockDatabase.foods_for_getFood["1"] = FoodItem(
            fdcId: 1,
            name: "Honey",
            fdcType: "foundation_food",
            nutrientGroups: [
                NutrientGroup(fdcNumber: "grp", name: "Minerals", nutrients: [
                    Nutrient(
                        fdcNumber: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                        name: "Calcium",
                        unitName: "mg",
                        amount: 10
                    )
                ])
            ],
            gramWeight: 100
        )

        let consumed = makeConsumedFood()
        let csv = service.generateCsv(consumedFoods: [consumed])
        let lines = csv.components(separatedBy: "\r\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("Calcium (mg)"))
        XCTAssertTrue(lines[1].hasPrefix("2026-06-01,Breakfast,Honey,1.000,cup,100.000"))
        XCTAssertTrue(lines[1].contains("10.000"))
    }

    func testMissingFoodStillProducesRowWithBlankNutrients() {
        let consumed = makeConsumedFood(fdcId: 999)
        let csv = service.generateCsv(consumedFoods: [consumed])
        let lines = csv.components(separatedBy: "\r\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].hasPrefix("2026-06-01,Breakfast,Honey,1.000,cup,100.000"))
    }

    func testRowsAreSortedByDateThenMealTime() {
        mockDatabase.foods_for_getFood["1"] = FoodItem(fdcId: 1, name: "A", fdcType: "t", nutrientGroups: [], gramWeight: 100)

        let dinnerFood = makeConsumedFood(
            name: "Dinner Food",
            dateLogged: SimpleDate(year: 2026, month: 6, day: 2)!,
            mealTime: .dinner
        )
        let breakfastFood = makeConsumedFood(
            name: "Breakfast Food",
            dateLogged: SimpleDate(year: 2026, month: 6, day: 1)!,
            mealTime: .breakfast
        )
        let lunchFood = makeConsumedFood(
            name: "Lunch Food",
            dateLogged: SimpleDate(year: 2026, month: 6, day: 1)!,
            mealTime: .lunch
        )

        let csv = service.generateCsv(consumedFoods: [dinnerFood, lunchFood, breakfastFood])
        let lines = csv.components(separatedBy: "\r\n")

        XCTAssertTrue(lines[1].contains("Breakfast Food"))
        XCTAssertTrue(lines[2].contains("Lunch Food"))
        XCTAssertTrue(lines[3].contains("Dinner Food"))
    }

    func testFieldsWithCommasAreQuoted() {
        let consumed = makeConsumedFood(name: "Chicken, Grilled")
        let csv = service.generateCsv(consumedFoods: [consumed])
        let lines = csv.components(separatedBy: "\r\n")

        XCTAssertTrue(lines[1].contains("\"Chicken, Grilled\""))
    }
}
