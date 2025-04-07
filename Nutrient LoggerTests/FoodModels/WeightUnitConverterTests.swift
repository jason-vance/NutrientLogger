//
//  WeightUnitConverterTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Testing

struct WeightUnitConverterTests {
    
    @Test
    public func testConvertsGramsToMilligrams() {
        testConvertsCorrectly(1, WeightUnit.gram, WeightUnit.milligram, 1000)
        testConvertsCorrectly(2, WeightUnit.gram, WeightUnit.milligram, 2000)
        testConvertsCorrectly(10, WeightUnit.gram, WeightUnit.milligram, 10000)
    }

    @Test
    public func testConvertsMilligramsToGrams() {
        testConvertsCorrectly(1000, WeightUnit.milligram, WeightUnit.gram, 1)
        testConvertsCorrectly(2000, WeightUnit.milligram, WeightUnit.gram, 2)
        testConvertsCorrectly(10000, WeightUnit.milligram, WeightUnit.gram, 10)
    }
    
    @Test
    public func testConvertsMilligramsToMicrograms() {
        testConvertsCorrectly(1, WeightUnit.milligram, WeightUnit.microgram, 1000)
        testConvertsCorrectly(2, WeightUnit.milligram, WeightUnit.microgram, 2000)
        testConvertsCorrectly(10, WeightUnit.milligram, WeightUnit.microgram, 10000)
    }
    
    @Test
    public func testConvertsMicrogramsToMilligrams() {
        testConvertsCorrectly(1000, WeightUnit.microgram, WeightUnit.milligram, 1)
        testConvertsCorrectly(2000, WeightUnit.microgram, WeightUnit.milligram, 2)
        testConvertsCorrectly(10000, WeightUnit.microgram, WeightUnit.milligram, 10)
    }
    
    @Test
    public func testConvertsMicrogramsToVitaminD_IU() {
        testConvertsCorrectly(0.025, WeightUnit.microgram, WeightUnit.vitaminD_IU, 1)
        testConvertsCorrectly(1, WeightUnit.microgram, WeightUnit.vitaminD_IU, 40)
        testConvertsCorrectly(2, WeightUnit.microgram, WeightUnit.vitaminD_IU, 80)
        testConvertsCorrectly(10, WeightUnit.microgram, WeightUnit.vitaminD_IU, 400)
    }
    
    @Test
    public func testConvertsVitaminD_IUToMicrograms() {
        testConvertsCorrectly(1, WeightUnit.vitaminD_IU, WeightUnit.microgram, 0.025)
        testConvertsCorrectly(40, WeightUnit.vitaminD_IU, WeightUnit.microgram, 1)
        testConvertsCorrectly(80, WeightUnit.vitaminD_IU, WeightUnit.microgram, 2)
        testConvertsCorrectly(400, WeightUnit.vitaminD_IU, WeightUnit.microgram, 10)
    }
    
    @Test
    public func testConvertsMicrogramsToVitaminA_IU() {
        testConvertsCorrectly(0.3, WeightUnit.microgram, WeightUnit.vitaminA_IU, 1)
        testConvertsCorrectly(1500, WeightUnit.microgram, WeightUnit.vitaminA_IU, 5000)
    }
    
    @Test
    public func testConvertsVitaminA_IUToMicrograms() {
        testConvertsCorrectly(1, WeightUnit.vitaminA_IU, WeightUnit.microgram, 0.3)
        testConvertsCorrectly(5000, WeightUnit.vitaminA_IU, WeightUnit.microgram, 1500)
    }

    private func testConvertsCorrectly(_ fromAmount: Double, _ fromUnit: WeightUnit, _ toUnit: WeightUnit, _ expected: Double) {
        let x = fromUnit.convertTo(toUnit, fromAmount)
        #expect(abs(expected - x) < 0.00001)
    }
}
