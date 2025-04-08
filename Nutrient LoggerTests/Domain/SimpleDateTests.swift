//
//  SimpleDateTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Testing

struct SimpleDateTests {
    
    @Test func testStartOfMonth() async throws {
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241001)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241002)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241003)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241004)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241005)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241009)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241019)!) == SimpleDate(rawValue: 20241001))
        #expect(SimpleDate.startOfMonth(containing: SimpleDate(rawValue: 20241031)!) == SimpleDate(rawValue: 20241001))
    }
    
    @Test func testEndOfMonth() async throws {
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240101)!) == SimpleDate(rawValue: 20240131))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240131)!) == SimpleDate(rawValue: 20240131))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240203)!) == SimpleDate(rawValue: 20240229))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240304)!) == SimpleDate(rawValue: 20240331))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240405)!) == SimpleDate(rawValue: 20240430))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240509)!) == SimpleDate(rawValue: 20240531))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240619)!) == SimpleDate(rawValue: 20240630))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240724)!) == SimpleDate(rawValue: 20240731))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240811)!) == SimpleDate(rawValue: 20240831))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20240912)!) == SimpleDate(rawValue: 20240930))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20241021)!) == SimpleDate(rawValue: 20241031))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20241101)!) == SimpleDate(rawValue: 20241130))
        #expect(SimpleDate.endOfMonth(containing: SimpleDate(rawValue: 20241221)!) == SimpleDate(rawValue: 20241231))
    }
    
    @Test func testStartOfYear() async throws {
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240101)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240202)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240303)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240504)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240805)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20240909)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20241119)!) == SimpleDate(rawValue: 20240101))
        #expect(SimpleDate.startOfYear(containing: SimpleDate(rawValue: 20241231)!) == SimpleDate(rawValue: 20240101))
    }
    
    @Test func testEndOfYear() async throws {
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240101)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240131)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240203)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240304)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240405)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240509)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240619)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240724)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240811)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20240912)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20241021)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20241101)!) == SimpleDate(rawValue: 20241231))
        #expect(SimpleDate.endOfYear(containing: SimpleDate(rawValue: 20241231)!) == SimpleDate(rawValue: 20241231))
    }
    
    @Test
    func addingWorksCorrectly() {
        let endOf2024 = SimpleDate(year: 2024, month: 12, day: 31)!
        let startOf2025 = endOf2024.adding(days: 1)
        let endOfJan2025 = endOf2024.adding(months: 1)
        let endOf2025 = endOf2024.adding(years: 1)
        
        let newYearsEveEve2024 = endOf2024.adding(days: -1)
        let endOfNov2024 = endOf2024.adding(months: -1)
        let endOf2023 = endOf2024.adding(years: -1)
        
        #expect(startOf2025 == SimpleDate(year: 2025, month: 1, day: 1))
        #expect(endOfJan2025 == SimpleDate(year: 2025, month: 1, day: 31))
        #expect(endOf2025 == SimpleDate(year: 2025, month: 12, day: 31))
        
        #expect(newYearsEveEve2024 == SimpleDate(year: 2024, month: 12, day: 30))
        #expect(endOfNov2024 == SimpleDate(year: 2024, month: 11, day: 30))
        #expect(endOf2023 == SimpleDate(year: 2023, month: 12, day: 31))

        
    }
}
