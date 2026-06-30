//
//  User.swift
//  User
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation

struct User: Codable {

    public var gender: Gender = Gender.unknown
    public var birthdate: SimpleDate? = nil

    public var calorieGoal: Double? = nil
    public var carbsGoalGrams: Double? = nil
    public var fatGoalGrams: Double? = nil
    public var proteinGoalGrams: Double? = nil
    public var micronutrientGoals: [String: Double] = [:]

    enum CodingKeys: String, CodingKey {
        case gender, birthdate
        case calorieGoal, carbsGoalGrams, fatGoalGrams, proteinGoalGrams
        case micronutrientGoals
    }

    init(
        gender: Gender = .unknown,
        birthdate: SimpleDate? = nil,
        calorieGoal: Double? = nil,
        carbsGoalGrams: Double? = nil,
        fatGoalGrams: Double? = nil,
        proteinGoalGrams: Double? = nil,
        micronutrientGoals: [String: Double] = [:]
    ) {
        self.gender = gender
        self.birthdate = birthdate
        self.calorieGoal = calorieGoal
        self.carbsGoalGrams = carbsGoalGrams
        self.fatGoalGrams = fatGoalGrams
        self.proteinGoalGrams = proteinGoalGrams
        self.micronutrientGoals = micronutrientGoals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender) ?? .unknown
        birthdate = try container.decodeIfPresent(SimpleDate.self, forKey: .birthdate)
        calorieGoal = try container.decodeIfPresent(Double.self, forKey: .calorieGoal)
        carbsGoalGrams = try container.decodeIfPresent(Double.self, forKey: .carbsGoalGrams)
        fatGoalGrams = try container.decodeIfPresent(Double.self, forKey: .fatGoalGrams)
        proteinGoalGrams = try container.decodeIfPresent(Double.self, forKey: .proteinGoalGrams)
        micronutrientGoals = try container.decodeIfPresent([String: Double].self, forKey: .micronutrientGoals) ?? [:]
    }

    public func getUserAge() -> TimeInterval? {
        guard let birthdate = birthdate?.toDate() else { return nil }
        return Date.now.timeIntervalSince(birthdate)
    }

    public static let sample: User = .init(
        gender: .male,
        birthdate: .init(year: 1987, month: 6, day: 16)
    )
}

extension User: Equatable { }
