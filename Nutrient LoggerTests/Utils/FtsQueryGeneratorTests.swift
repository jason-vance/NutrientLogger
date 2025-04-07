//
//  FtsQueryGeneratorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/6/25.
//

import Testing

struct FtsQueryGeneratorTests {

    @Test func testQueries() async throws {
        testQueryGenerator("milk", "milk*")
        testQueryGenerator("whole milk", "whole* OR milk*")
        testQueryGenerator("whole, milk", "whole* OR milk*")
        testQueryGenerator("whole , milk", "whole* OR milk*")
        testQueryGenerator("whole    milk", "whole* OR milk*")
        testQueryGenerator("whole milk dessert bar", "whole* OR milk* OR dessert* OR bar*")
        testQueryGenerator("bagels", "bagel*")
        testQueryGenerator("BAGELS", "BAGEL*")
        testQueryGenerator("dresses", "dress*")
        testQueryGenerator("DRESSES", "DRESS*")
    }
    
    public func testQueryGenerator(_ input: String, _ expectedOutput: String) {
        let x = FtsQueryGenerator.generateFrom(input)
        #expect(expectedOutput == x)
    }
    
    public func testWithoutPunctuation() {
        let query = "whole, milk"
        let expected = "whole milk"
        
        let x = FtsQueryGenerator.withoutPunctuation(query)
        
        #expect(expected == x)
    }
    
    public func testWithoutSuffixes() {
        let query = "dresses"
        let expected = "dress"
        
        let x = FtsQueryGenerator.withoutPluralization(query)
        
        #expect(expected == x)
    }

}
