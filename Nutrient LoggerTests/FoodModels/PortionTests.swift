//
//  PortionTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Testing

struct PortionTests_BundledFdcDatabase {

    @Test public func testPortionFrom_ConvertsCorrectly() throws {
        test(1, "asdf", 50, 1, "asdf", 50)
        test(1, "2.5 asdf", 50, 2.5, "asdf", 20)
        test(1, "asdf asdf", 50, 1, "asdf asdf", 50)
        test(0, "1.5 fl oz", 30, 1.5, "fl oz", 20)
        test(1, "oz", 28.35, 1, "oz", 28.35)
        test(0.5, "oz", 14.2, 0.5, "oz", 28.4)
    }

    private func test(_ amount: Double, _ desc: String, _ gramWeight: Double, _ expectedAmount: Double, _ expectedeDesc: String, _ expectedGrams: Double) {
        let localFdcPortion = FdcPortion(
            id: -1,
            fdcId: -1,
            sequenceNumber: -1,
            amount: amount,
            description: desc,
            modifier: nil,
            gramWeight: gramWeight
        )

        let x = BundledFdcDatabase.portionFrom(localFdcPortion)

        #expect(expectedAmount == x.amount)
        #expect(expectedeDesc == x.name)
        #expect(expectedGrams == x.gramWeight)
    }
}
