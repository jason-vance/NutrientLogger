//
//  BundledDatabaseVersion.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/6/26.
//

import Foundation

/// The bundled food databases are copied to Application Support on first launch and opened from
/// there. Without a version, an update that changes a bundled database never reaches people who
/// already have a copy. Bump a database's number when its contents change.
enum BundledDatabaseVersion {

    /// 2: survey foods gained pantothenic acid and manganese, calculated from their USDA
    /// ingredients (scripts/fill_survey_nutrients.py), Nov 2026.
    static let current: [String: Int] = [
        "fdc_survey.db": 2,
    ]

    /// Copies made before versioning existed count as version 1.
    static let unversioned = 1

    static func key(for dbName: String) -> String { "bundledDbVersion.\(dbName)" }

    static func needsCopy(fileExists: Bool, installedVersion: Int?, bundledVersion: Int) -> Bool {
        guard fileExists else { return true }
        return (installedVersion ?? unversioned) < bundledVersion
    }
}
