//
//  Matches.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation
import Testing

struct Matches {
    
    @Test func testMatches() {
        //Gender matching
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.unknown, 0.5, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.male, 0.5, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.female, 0.5, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.male, 0.5, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.female, 0.5, true)
        matchesGenderAndAge(Gender.male, 0.0, 1.0, Gender.unknown, 0.5, true)
        matchesGenderAndAge(Gender.female, 0.0, 1.0, Gender.unknown, 0.5, true)
        matchesGenderAndAge(Gender.male, 0.0, 1.0, Gender.male, 0.5, true)
        matchesGenderAndAge(Gender.female, 0.0, 1.0, Gender.female, 0.5, true)
        matchesGenderAndAge(Gender.female, 0.0, 1.0, Gender.male, 0.5, false)
        matchesGenderAndAge(Gender.male, 0.0, 1.0, Gender.female, 0.5, false)
        //Age matching
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.unknown, 0.0, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.unknown, 0.9999, true)
        matchesGenderAndAge(Gender.unknown, 0.0, 1.0, Gender.unknown, 1.0, false)
        //Both gender and age
        matchesGenderAndAge(Gender.male, 0.0, 1.0, Gender.female, 2.0, false)
        matchesGenderAndAge(Gender.female, 0.0, 1.0, Gender.male, 3.0, false)
    }
    
    func matchesGenderAndAge(_ rdiGender: Gender, _ rdiMinAgeYears: Double, _ rdiMaxAgeYears: Double, _ queryGender: Gender, _ queryAgeYears: Double, _ shouldMatch: Bool) {
        let queryAgeSeconds = TimeInterval(queryAgeYears * 365.0 * 86400.0)

        let rdi = LifeStageNutrientRdi()
        rdi.gender = rdiGender
        rdi.maxAgeYears = rdiMinAgeYears
        rdi.maxAgeYears = rdiMaxAgeYears

        let matches = rdi.matches(queryGender, queryAgeSeconds)

        #expect(shouldMatch == matches)
    }
}
