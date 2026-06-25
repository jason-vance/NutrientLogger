//
//  ScreenshotDataSeeder.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/25/26.
//

import Foundation
import SwiftData

@MainActor
class ScreenshotDataSeeder {

    static func seed(into context: ModelContext) {
        seedConsumedFoods(into: context)
        seedDailySummaries(into: context)
        seedWeightEntries(into: context)
        seedBodyFatEntries(into: context)
        seedMeals(into: context)
        seedRecentSearches(into: context)
        try? context.save()
    }

    // MARK: - Food Templates (real FDC IDs from bundled database)

    private struct FoodTemplate {
        let fdcId: Int
        let name: String
        let portionAmount: Double
        let portionGramWeight: Double
        let portionName: String
    }

    private static let breakfastFoods: [[FoodTemplate]] = [
        [
            FoodTemplate(fdcId: 1100236, name: "Scrambled eggs", portionAmount: 2, portionGramWeight: 55, portionName: "egg"),
            FoodTemplate(fdcId: 1100741, name: "Whole wheat toast", portionAmount: 2, portionGramWeight: 33, portionName: "slice"),
            FoodTemplate(fdcId: 1102613, name: "Orange juice", portionAmount: 1, portionGramWeight: 248, portionName: "cup"),
        ],
        [
            FoodTemplate(fdcId: 1101577, name: "Oatmeal", portionAmount: 1, portionGramWeight: 240, portionName: "cup, cooked"),
            FoodTemplate(fdcId: 1102702, name: "Blueberries, raw", portionAmount: 1, portionGramWeight: 150, portionName: "cup"),
            FoodTemplate(fdcId: 1103956, name: "Honey", portionAmount: 1, portionGramWeight: 20, portionName: "tbsp"),
        ],
        [
            FoodTemplate(fdcId: 1097562, name: "Greek yogurt, plain", portionAmount: 1, portionGramWeight: 170, portionName: "6 oz container"),
            FoodTemplate(fdcId: 1102653, name: "Banana, raw", portionAmount: 1, portionGramWeight: 126, portionName: "banana"),
            FoodTemplate(fdcId: 1100507, name: "Almonds", portionAmount: 1, portionGramWeight: 28.35, portionName: "oz"),
        ],
    ]

    private static let lunchFoods: [[FoodTemplate]] = [
        [
            FoodTemplate(fdcId: 1098445, name: "Grilled chicken breast", portionAmount: 1, portionGramWeight: 120, portionName: "medium breast"),
            FoodTemplate(fdcId: 1101626, name: "Brown rice", portionAmount: 1, portionGramWeight: 196, portionName: "cup, cooked"),
            FoodTemplate(fdcId: 1103172, name: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 155, portionName: "cup"),
        ],
        [
            FoodTemplate(fdcId: 1098962, name: "Salmon, baked", portionAmount: 1, portionGramWeight: 170, portionName: "small fillet"),
            FoodTemplate(fdcId: 1103861, name: "Olive oil", portionAmount: 1, portionGramWeight: 14, portionName: "tbsp"),
            FoodTemplate(fdcId: 1103172, name: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 78, portionName: "half cup"),
        ],
        [
            FoodTemplate(fdcId: 1098445, name: "Grilled chicken breast", portionAmount: 1, portionGramWeight: 135, portionName: "large breast"),
            FoodTemplate(fdcId: 1103172, name: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 155, portionName: "cup"),
            FoodTemplate(fdcId: 1103861, name: "Olive oil", portionAmount: 1, portionGramWeight: 14, portionName: "tbsp"),
        ],
    ]

    private static let dinnerFoods: [[FoodTemplate]] = [
        [
            FoodTemplate(fdcId: 1098962, name: "Salmon, baked", portionAmount: 1, portionGramWeight: 170, portionName: "small fillet"),
            FoodTemplate(fdcId: 1101626, name: "Brown rice", portionAmount: 1, portionGramWeight: 196, portionName: "cup, cooked"),
            FoodTemplate(fdcId: 1103172, name: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 155, portionName: "cup"),
        ],
        [
            FoodTemplate(fdcId: 1098445, name: "Grilled chicken breast", portionAmount: 1, portionGramWeight: 120, portionName: "medium breast"),
            FoodTemplate(fdcId: 1101626, name: "Brown rice", portionAmount: 1, portionGramWeight: 196, portionName: "cup, cooked"),
            FoodTemplate(fdcId: 1100456, name: "Soy sauce", portionAmount: 1, portionGramWeight: 16, portionName: "tbsp"),
        ],
        [
            FoodTemplate(fdcId: 1098962, name: "Salmon, baked", portionAmount: 1, portionGramWeight: 227, portionName: "medium fillet"),
            FoodTemplate(fdcId: 1103172, name: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 155, portionName: "cup"),
            FoodTemplate(fdcId: 1103861, name: "Olive oil", portionAmount: 1, portionGramWeight: 14, portionName: "tbsp"),
        ],
    ]

    private static let snackFoods: [FoodTemplate] = [
        FoodTemplate(fdcId: 1102644, name: "Apple, raw", portionAmount: 1, portionGramWeight: 200, portionName: "medium"),
        FoodTemplate(fdcId: 1100507, name: "Almonds", portionAmount: 1, portionGramWeight: 28.35, portionName: "oz"),
        FoodTemplate(fdcId: 1097562, name: "Greek yogurt, plain", portionAmount: 1, portionGramWeight: 150, portionName: "container"),
        FoodTemplate(fdcId: 1102653, name: "Banana, raw", portionAmount: 1, portionGramWeight: 126, portionName: "banana"),
        FoodTemplate(fdcId: 1100559, name: "Peanut butter", portionAmount: 1, portionGramWeight: 32, portionName: "serving"),
        FoodTemplate(fdcId: 1102702, name: "Blueberries, raw", portionAmount: 1, portionGramWeight: 150, portionName: "cup"),
        FoodTemplate(fdcId: 1097512, name: "Whole milk", portionAmount: 1, portionGramWeight: 244, portionName: "cup"),
    ]

    // MARK: - Consumed Foods (past 8 days including today)

    private static func seedConsumedFoods(into context: ModelContext) {
        let today = SimpleDate.today

        for dayOffset in 0..<8 {
            let date = today.adding(days: -dayOffset)

            let breakfastSet = breakfastFoods[dayOffset % breakfastFoods.count]
            for food in breakfastSet {
                context.insert(ConsumedFood(
                    fdcId: food.fdcId, name: food.name,
                    portionAmount: food.portionAmount, portionGramWeight: food.portionGramWeight,
                    portionName: food.portionName, dateLogged: date, mealTime: .breakfast
                ))
            }

            let lunchSet = lunchFoods[dayOffset % lunchFoods.count]
            for food in lunchSet {
                context.insert(ConsumedFood(
                    fdcId: food.fdcId, name: food.name,
                    portionAmount: food.portionAmount, portionGramWeight: food.portionGramWeight,
                    portionName: food.portionName, dateLogged: date, mealTime: .lunch
                ))
            }

            let snack = snackFoods[dayOffset % snackFoods.count]
            context.insert(ConsumedFood(
                fdcId: snack.fdcId, name: snack.name,
                portionAmount: snack.portionAmount, portionGramWeight: snack.portionGramWeight,
                portionName: snack.portionName, dateLogged: date, mealTime: .afternoonSnack
            ))

            let dinnerSet = dinnerFoods[dayOffset % dinnerFoods.count]
            for food in dinnerSet {
                context.insert(ConsumedFood(
                    fdcId: food.fdcId, name: food.name,
                    portionAmount: food.portionAmount, portionGramWeight: food.portionGramWeight,
                    portionName: food.portionName, dateLogged: date, mealTime: .dinner
                ))
            }
        }
    }

    // MARK: - Daily Summaries (past 45 days)

    private static func seedDailySummaries(into context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<45 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let (cal, pro, carb, fat, water) = macrosForDay(dayOffset)
            context.insert(DailySummary(
                date: calendar.startOfDay(for: date),
                calories: cal,
                protein: pro,
                carbs: carb,
                fat: fat,
                waterGrams: water
            ))
        }
    }

    private static func macrosForDay(_ dayOffset: Int) -> (Double, Double, Double, Double, Double) {
        let dayOfWeek = dayOffset % 7

        let baseCal: Double
        let basePro: Double
        let baseCarb: Double
        let baseFat: Double
        let baseWater: Double

        switch dayOfWeek {
        case 0:
            baseCal = 2150; basePro = 135; baseCarb = 240; baseFat = 72; baseWater = 2370
        case 1:
            baseCal = 1980; basePro = 142; baseCarb = 210; baseFat = 65; baseWater = 2600
        case 2:
            baseCal = 2280; basePro = 128; baseCarb = 265; baseFat = 78; baseWater = 2130
        case 3:
            baseCal = 2050; basePro = 150; baseCarb = 220; baseFat = 68; baseWater = 2840
        case 4:
            baseCal = 2320; basePro = 138; baseCarb = 255; baseFat = 82; baseWater = 2490
        case 5:
            baseCal = 1890; basePro = 118; baseCarb = 195; baseFat = 70; baseWater = 1900
        case 6:
            baseCal = 2450; basePro = 125; baseCarb = 290; baseFat = 88; baseWater = 2200
        default:
            baseCal = 2100; basePro = 130; baseCarb = 230; baseFat = 72; baseWater = 2370
        }

        let variation = Double((dayOffset * 17 + 13) % 11) / 100.0 - 0.05

        return (
            (baseCal * (1 + variation)).rounded(),
            (basePro * (1 + variation * 0.8)).rounded(),
            (baseCarb * (1 + variation * 1.1)).rounded(),
            (baseFat * (1 + variation * 0.7)).rounded(),
            (baseWater * (1 + variation * 0.5)).rounded()
        )
    }

    // MARK: - Weight Entries (past 90 days, trending DOWN)

    private static func seedWeightEntries(into context: ModelContext) {
        let today = SimpleDate.today

        let pastWeight = 84.5
        let currentWeight = 77.8
        let totalDays = 90
        let weightPerDay = (pastWeight - currentWeight) / Double(totalDays)

        for dayOffset in stride(from: 0, to: totalDays, by: 1) {
            guard dayOffset % 2 == 0 || dayOffset % 7 == 0 else { continue }

            let date = today.adding(days: -dayOffset)
            let trend = currentWeight + weightPerDay * Double(dayOffset)
            let jitter = Double((dayOffset * 31 + 7) % 13) / 10.0 - 0.6
            let weight = trend + jitter
            let rounded = (weight * 10).rounded() / 10

            context.insert(WeightEntry(date: date, weightKg: rounded))
        }
    }

    // MARK: - Body Fat Entries (past 90 days, trending DOWN)

    private static func seedBodyFatEntries(into context: ModelContext) {
        let today = SimpleDate.today

        let pastBf = 23.5
        let currentBf = 19.8
        let totalDays = 90
        let bfPerDay = (pastBf - currentBf) / Double(totalDays)

        for dayOffset in stride(from: 0, to: totalDays, by: 1) {
            guard dayOffset % 3 == 0 || dayOffset % 7 == 1 else { continue }

            let date = today.adding(days: -dayOffset)
            let trend = currentBf + bfPerDay * Double(dayOffset)
            let jitter = Double((dayOffset * 23 + 5) % 9) / 10.0 - 0.4
            let bf = trend + jitter
            let rounded = (bf * 10).rounded() / 10

            context.insert(BodyFatEntry(date: date, percentage: rounded))
        }
    }

    // MARK: - Saved Meals (real FDC IDs)

    private static func seedMeals(into context: ModelContext) {
        let shake = Meal(name: "Post-Workout Shake")
        shake.addFoods([
            .init(foodFdcId: 1104520, foodName: "Whey protein powder", portionAmount: 2, portionGramWeight: 19.5, portionName: "scoop"),
            .init(foodFdcId: 1102653, foodName: "Banana, raw", portionAmount: 1, portionGramWeight: 126, portionName: "banana"),
            .init(foodFdcId: 1097512, foodName: "Whole milk", portionAmount: 1, portionGramWeight: 244, portionName: "cup"),
            .init(foodFdcId: 1100559, foodName: "Peanut butter", portionAmount: 1, portionGramWeight: 32, portionName: "serving"),
        ])
        context.insert(shake)

        let bowl = Meal(name: "Chicken & Rice Bowl")
        bowl.addFoods([
            .init(foodFdcId: 1098445, foodName: "Grilled chicken breast", portionAmount: 1, portionGramWeight: 120, portionName: "medium breast"),
            .init(foodFdcId: 1101626, foodName: "Brown rice", portionAmount: 1, portionGramWeight: 196, portionName: "cup, cooked"),
            .init(foodFdcId: 1103172, foodName: "Broccoli, cooked", portionAmount: 1, portionGramWeight: 78, portionName: "half cup"),
            .init(foodFdcId: 1100456, foodName: "Soy sauce", portionAmount: 1, portionGramWeight: 16, portionName: "tbsp"),
        ])
        context.insert(bowl)

        let oatmeal = Meal(name: "Morning Oatmeal")
        oatmeal.addFoods([
            .init(foodFdcId: 1101577, foodName: "Oatmeal", portionAmount: 1, portionGramWeight: 240, portionName: "cup, cooked"),
            .init(foodFdcId: 1102702, foodName: "Blueberries, raw", portionAmount: 0.5, portionGramWeight: 150, portionName: "cup"),
            .init(foodFdcId: 1103956, foodName: "Honey", portionAmount: 1, portionGramWeight: 20, portionName: "tbsp"),
            .init(foodFdcId: 1100507, foodName: "Almonds, sliced", portionAmount: 1, portionGramWeight: 28.35, portionName: "oz"),
        ])
        context.insert(oatmeal)
    }

    // MARK: - Recent Searches

    private static func seedRecentSearches(into context: ModelContext) {
        let searches = ["chicken breast", "salmon", "brown rice", "greek yogurt", "almonds", "broccoli"]
        for (i, query) in searches.enumerated() {
            let date = Date().addingTimeInterval(TimeInterval(-i * 3600))
            context.insert(RecentSearch(query: query, date: date))
        }
    }
}
