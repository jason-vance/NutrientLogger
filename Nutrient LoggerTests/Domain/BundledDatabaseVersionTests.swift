//
//  BundledDatabaseVersionTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 11/6/26.
//

import Testing

struct BundledDatabaseVersionTests {

    @Test func copiesOnAFreshInstall() {
        #expect(BundledDatabaseVersion.needsCopy(fileExists: false, installedVersion: nil, bundledVersion: 1))
    }

    @Test func replacesACopyFromBeforeVersioning() {
        #expect(BundledDatabaseVersion.needsCopy(fileExists: true, installedVersion: nil, bundledVersion: 2))
        #expect(!BundledDatabaseVersion.needsCopy(fileExists: true, installedVersion: nil, bundledVersion: 1))
    }

    @Test func keepsAnUpToDateCopy() {
        #expect(!BundledDatabaseVersion.needsCopy(fileExists: true, installedVersion: 2, bundledVersion: 2))
        #expect(BundledDatabaseVersion.needsCopy(fileExists: true, installedVersion: 2, bundledVersion: 3))
    }

    @Test func theSurveyDatabaseIsNewerThanOldInstalls() {
        #expect((BundledDatabaseVersion.current["fdc_survey.db"] ?? 0) > BundledDatabaseVersion.unversioned)
    }
}
