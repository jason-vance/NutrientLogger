//
//  FirstDayReminder.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 11/11/26.
//

import Foundation

/// The evening reminder for a new user who hasn't logged a full day yet. The first full day
/// (breakfast, lunch and dinner) is when the app names what their diet ran short on, so until then
/// the reminder points at that payoff instead of the usual "you haven't logged since lunch".
enum FirstDayReminder {

    /// How many days after onboarding starts the reminder keeps steering toward a first full day,
    /// so someone who never logs all three meals doesn't hear about it forever.
    static let days = 7

    /// Whether a user is still working toward their first full day: within `days` of starting
    /// onboarding, with no full day so far. Users from before onboarding was timed (a start of 0)
    /// aren't new.
    static func applies(onboardingStartedAt: Double, hasHadFullDay: Bool, now: Date, calendar: Calendar = .current) -> Bool {
        guard !hasHadFullDay,
              let day = FirstFullDayTiming.dayNumber(onboardingStartedAt: onboardingStartedAt, now: now, calendar: calendar)
        else { return false }
        return day <= days
    }

    /// - Parameters:
    ///   - mealTimesLogged: Meals with something logged on the day the reminder fires.
    ///   - hasLoggedBefore: Whether anything was logged on an earlier day.
    ///   - diet: The diet picked during setup, named in the text ("your carnivore day").
    static func message(
        mealTimesLogged: Set<MealTime>,
        hasLoggedBefore: Bool,
        diet: NutritionDietPreset?
    ) -> NotificationPlanner.Message {
        let day = dayName(diet).map { "your \($0) day" } ?? "your day"
        let missing = FullLoggingDay.requiredMealTimes.filter { !mealTimesLogged.contains($0) }

        if mealTimesLogged.isEmpty && !hasLoggedBefore {
            return .init(
                title: "What did you eat today?",
                body: "Log a meal to see its vitamins and minerals, not just its calories."
            )
        }
        if mealTimesLogged.isEmpty || missing.isEmpty {
            return .init(
                title: "One full day shows your gaps",
                body: "Log breakfast, lunch and dinner today to see which vitamins and minerals \(day) is short on."
            )
        }
        return .init(
            title: missing.count == 1 ? "One meal to go" : "Finish today to see your gaps",
            body: "Log \(FirstDayRecap.naturalList(missing.map { $0.rawValue.lowercased() })) to see which vitamins and minerals \(day) is short on."
        )
    }

    /// How the diet reads before "day". Nil for balanced, which needs no label.
    static func dayName(_ diet: NutritionDietPreset?) -> String? {
        switch diet {
        case .carnivore: "carnivore"
        case .ketoLowCarb: "keto"
        case .paleo: "paleo"
        case .plantBased: "plant-based"
        case .pescatarian: "pescatarian"
        case .balanced, nil: nil
        }
    }
}
