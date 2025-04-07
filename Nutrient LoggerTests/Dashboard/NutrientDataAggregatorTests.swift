//
//  NutrientDataAggregatorTests.swift
//  Nutrient LoggerTests
//
//  Created by Jason Vance on 4/7/25.
//

import Testing

struct NutrientDataAggregatorTests {
    
    @Test func testUsesFirstNutrientsUnit() throws {
        var nutrients = [Nutrient]()

        nutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.milligram.name
        ))
        nutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.gram.name
        ))

        var aggregate = NutrientDataAggregator.combineNutrients(nutrients)
        #expect(WeightUnit.milligram.name == aggregate?.unitName)

        nutrients.insert(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.gram.name
        ), at: 0)

        aggregate = NutrientDataAggregator.combineNutrients(nutrients)
        #expect(WeightUnit.gram.name == aggregate?.unitName)
    }
    
    @Test func testAddsNutrientsTogether() throws {
        var nutrients = [Nutrient]()
        
        nutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.milligram.name,
            amount: 500))
        nutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.milligram.name,
            amount: 750))
        nutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "",
            name: "",
            unitName: WeightUnit.gram.name,
            amount: 1))

        guard let aggregate = NutrientDataAggregator.combineNutrients(nutrients) else {
            Issue.record("`aggregate` was nil")
            return
        }
        
        #expect(2250 == aggregate.amount)
        #expect(WeightUnit.milligram.name == aggregate.unitName)
    }
    
    @Test func testAggregatesFoods() throws {
        var proximateNutrients = [Nutrient]()
        proximateNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "203",
            name: "Protein",
            unitName: WeightUnit.milligram.name,
            amount: 5))
        proximateNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "202",
            name: "Nitrogen",
            unitName: WeightUnit.gram.name,
            amount: 1))

        var mineralNutrients = [Nutrient]()
        mineralNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "301",
            name: "Calcium",
            unitName: WeightUnit.microgram.name,
            amount: 5))
        mineralNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "303",
            name: "Iron",
            unitName: WeightUnit.microgram.name,
            amount: 3))

        var vitaminNutrients = [Nutrient]()
        vitaminNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "404",
            name: "Thiamin",
            unitName: WeightUnit.microgram.name,
            amount: 500))
        vitaminNutrients.append(Nutrient(
            fdcId: 0,
            fdcNumber: "406",
            name: "Niacin",
            unitName: WeightUnit.microgram.name,
            amount: 3))

        var groups0 = [NutrientGroup]()
        groups0.append(NutrientGroup(
            fdcNumber: "951",
            name: "Proximates",
            nutrients: proximateNutrients))
        groups0.append(NutrientGroup(
            fdcNumber: "300",
            name: "Minerals",
            nutrients: mineralNutrients))

        var groups1 = [NutrientGroup]()
        groups1.append(NutrientGroup(
            fdcNumber: "951",
            name: "Proximates",
            nutrients: proximateNutrients))
        groups1.append(NutrientGroup(
            fdcNumber: "952",
            name: "Vitamins",
            nutrients: vitaminNutrients))

        var foods = [FoodItem]()
        foods.append(FoodItem(
            nutrientGroups: groups0,
            amount: 0,
            gramWeight: 0))
        foods.append(FoodItem(
            nutrientGroups: groups1,
            amount: 0,
            gramWeight: 0))

        let aggregator = NutrientDataAggregator(foods)
        let aggregatedGroups = aggregator.nutrientGroups

        #expect(3 == aggregatedGroups.count)
        #expect(2 == aggregatedGroups[1].nutrients.count)
        #expect(2 == aggregatedGroups[2].nutrients.count)


        let proximateGroup = aggregatedGroups.first { "951" == $0.fdcNumber }!
        #expect(2 == proximateGroup.nutrients.count)

        let protein = proximateGroup.nutrients.first { "203" == $0.fdcNumber }!
        #expect(10 == protein.amount)
        #expect(WeightUnit.milligram.name == protein.unitName)

        let nitrogen = proximateGroup.nutrients.first { "202" == $0.fdcNumber }!
        #expect(2 == nitrogen.amount)
        #expect(WeightUnit.gram.name == nitrogen.unitName)


        let mineralGroup = aggregatedGroups.first { "300" == $0.fdcNumber }!
        #expect(2 == mineralGroup.nutrients.count)

        let calcium = mineralGroup.nutrients.first { "301" == $0.fdcNumber }!
        #expect(5 == calcium.amount)
        #expect(WeightUnit.microgram.name == calcium.unitName)

        let iron = mineralGroup.nutrients.first { "303" == $0.fdcNumber }!
        #expect(3 == iron.amount)
        #expect(WeightUnit.microgram.name == iron.unitName)


        let vitaminGroup = aggregatedGroups.first { "952" == $0.fdcNumber }!
        #expect(2 == vitaminGroup.nutrients.count)

        let thiamin = vitaminGroup.nutrients.first { "404" == $0.fdcNumber }!
        #expect(500 == thiamin.amount)
        #expect(WeightUnit.microgram.name == thiamin.unitName)

        let niacin = vitaminGroup.nutrients.first { "406" == $0.fdcNumber }!
        #expect(3 == niacin.amount)
        #expect(WeightUnit.microgram.name == niacin.unitName)
    }

}
