//
//  DatabaseDataTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import Testing

struct DatabaseDataTests {
    
    @Test func testSetDateFormatsIntCorrectly() {
        setDateFormatsIntCorrectly(2020, 10, 13, 0, 0, 0, 20201013000000)
        setDateFormatsIntCorrectly(2020, 4, 13, 1, 2, 3, 20200413010203)
        setDateFormatsIntCorrectly(2020, 10, 4, 13, 45, 32, 20201004134532)
        setDateFormatsIntCorrectly(2020, 1, 1, 14, 14, 14, 20200101141414)
        setDateFormatsIntCorrectly(999, 10, 13, 3, 42, 43, 9991013034243)
    }
    
    func setDateFormatsIntCorrectly(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int, _ expected: Int64) {
        let date = Date.from(year: year, month: month, day: day, hr: hour, min: minute, sec: second)
         
        let xInt = DatabaseDate.from(date)
        #expect(expected == xInt)
        
        let xDate = xInt.toDate()
        #expect(date == xDate)
    }
    
//    @Test func testToDatePerformance() throws {
//        self.measure {
//            for minute in 0..<60 {
//                for second in 0..<60 {
//                    let dbDate = DatabaseDate(20200102030000 + (minute * 100) + second)
//                    _ = dbDate.toDate()
//                }
//            }
//        }
//    }
}
