//
//  DashboardMacrosSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/29/25.
//

import SwiftUI

struct DashboardMacrosSection: View {
    
    let calsKey = FdcNutrientGroupMapper.NutrientNumber_Energy_KCal
    let carbsKey = FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference
    let proteinKey = FdcNutrientGroupMapper.NutrientNumber_Protein
    let fatKey = FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat
    let waterKey = FdcNutrientGroupMapper.NutrientNumber_Water
    let kjKey = FdcNutrientGroupMapper.NutrientNumber_Energy_Kj

    let aggregator: NutrientDataAggregator
    
    private var calories: Double {
        if let cals = aggregator.nutrientsByNutrientNumber[calsKey] {
            return cals.reduce(0.0) { $0 + $1.nutrient.amount }
        }
        return 0
    }
    
    private var caloriesUnit: String {
        if let cals = aggregator.nutrientsByNutrientNumber[calsKey], let first = cals.first {
            return first.nutrient.unitName
        }
        return "cals"
    }
    
    private var carbs: Double {
        if let carbs = aggregator.nutrientsByNutrientNumber[carbsKey] {
            return carbs.reduce(0.0) { $0 + $1.nutrient.amount }
        }
        return 0
    }
    
    private var carbsUnit: String {
        if let carbs = aggregator.nutrientsByNutrientNumber[carbsKey], let first = carbs.first {
            return first.nutrient.unitName
        }
        return "g"
    }
    
    private var fat: Double {
        if let fats = aggregator.nutrientsByNutrientNumber[fatKey] {
            return fats.reduce(0.0) { $0 + $1.nutrient.amount }
        }
        return 0
    }
    
    private var fatUnit: String {
        if let fats = aggregator.nutrientsByNutrientNumber[fatKey], let first = fats.first {
            return first.nutrient.unitName
        }
        return "g"
    }
    
    private var protein: Double {
        if let proteins = aggregator.nutrientsByNutrientNumber[proteinKey] {
            return proteins.reduce(0.0) { $0 + $1.nutrient.amount }
        }
        return 0
    }
    
    private var proteinUnit: String {
        if let proteins = aggregator.nutrientsByNutrientNumber[proteinKey], let first = proteins.first {
            return first.nutrient.unitName
        }
        return "g"
    }
    
    private var totalMacros: Double {
        return carbs + fat + protein
    }
    
    private var waterGrams: Double? {
        if let waters = aggregator.nutrientsByNutrientNumber[waterKey] {
            return waters.reduce(0.0) { $0 + $1.nutrient.amount }
        }
        return nil
    }
    
    private var otherNutrientIds: [String] {
        let proximatesNum = FdcNutrientGroupMapper.GroupNumber_Proximates
        
        guard let proximates = aggregator.nutrientGroups
            .first(where: { $0.fdcNumber == proximatesNum })
        else {
            return []
        }
        
        let dontInclude = [calsKey, proteinKey, fatKey, carbsKey, waterKey, kjKey]
        return Set(proximates.nutrients.map(\.fdcNumber))
            .filter({ !dontInclude.contains($0) })
            .sorted { $0 < $1 }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Macros")
                    .listSectionHeader()
                Spacer()
            }
            CaloriesCard()
                .padding()
                .inCard()
            CarbsFatProtein()
            Water()
            OtherStuff()
        }
    }
    
    @ViewBuilder private func CaloriesCard() -> some View {
        let lineWidthPts: CGFloat = 32
        
        HStack {
            Spacer()
            GeometryReader { geometry in
                ZStack {
                    if totalMacros > 0 {
                        let circumference: CGFloat = geometry.size.width * .pi
                        let lineWidth: CGFloat = lineWidthPts / circumference
                        let margin: CGFloat = 8 / circumference
                        let carbStart: CGFloat = (lineWidth / 2) + (margin / 2)
                        let carbEnd = CGFloat(carbs / totalMacros) - (lineWidth / 2) - (margin / 2)
                        let fatStart = carbEnd + lineWidth + margin
                        let fatEnd = CGFloat(fat / totalMacros) + fatStart - (lineWidth / 2) - (margin / 2)
                        let proteinStart = fatEnd + lineWidth + margin
                        let proteinEnd: CGFloat = 1 - (lineWidth / 2) - (margin / 2)
                        
                        Circle()
                            .trim(from: carbStart, to: carbEnd)
                            .stroke(style: .init(
                                lineWidth: lineWidthPts,
                                lineCap: .round
                            ))
                            .foregroundStyle(Color.indigo)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .trim(from: fatStart, to: fatEnd)
                            .stroke(style: .init(
                                lineWidth: lineWidthPts,
                                lineCap: .round
                            ))
                            .foregroundStyle(Color.red)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .trim(from: proteinStart, to: proteinEnd)
                            .stroke(style: .init(
                                lineWidth: lineWidthPts,
                                lineCap: .round
                            ))
                            .foregroundStyle(Color.green)
                            .rotationEffect(.degrees(-90))
                    } else {
                        Circle()
                            .stroke(style: .init(
                                lineWidth: lineWidthPts,
                                lineCap: .round
                            ))
                            .foregroundStyle(Color.gray)
                    }
                    VStack {
                        Text("Total Calories")
                            .font(.headline)
                            .fontWeight(.light)
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.orange)
                            Text("\(calories.formatted(maxDigits: 0))")
                                .contentTransition(.numericText())
                        }
                        .font(.title)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    }
                    .offset(y: -5)
                }
            }
            .frame(width: 250, height: 250)
            Spacer()
        }
        .padding(lineWidthPts / 2)
    }
    
    @ViewBuilder private func CarbsFatProtein() -> some View {
        HStack {
            Macro(
                name: "Carbs",
                iconName: "square.fill",
                iconColor: .indigo,
                amount: carbs,
                unit: carbsUnit
            )
            Macro(
                name: "Fat",
                iconName: "circle.fill",
                iconColor: .red,
                amount: fat,
                unit: fatUnit
            )
            Macro(
                name: "Protein",
                iconName: "triangle.fill",
                iconColor: .green,
                amount: protein,
                unit: proteinUnit
            )
        }
    }
    
    @ViewBuilder private func Macro(
        name: String,
        iconName: String,
        iconColor: Color,
        amount: Double,
        unit: String,
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
            }
            HStack(spacing: 4) {
                MacroIcon(name: iconName)
                    .foregroundStyle(iconColor)
                Text("\(amount.formatted(maxDigits: 0))\(unit)")
                    .contentTransition(.numericText())
            }
            .font(.title2)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
        }
        .padding()
        .inCard()
    }
    
    @ViewBuilder private func MacroIcon(name: String) -> some View {
        ZStack {
            Image(systemName: name)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(2)
                .background {
                    Image(systemName: name)
                        .resizable()
                        .foregroundStyle(Color.white)
                }
                .offset(x: -3, y: 6)
            Image(systemName: name)
                .resizable()
                .frame(width: 12, height: 12)
                .padding(2)
                .background {
                    Image(systemName: name)
                        .resizable()
                        .foregroundStyle(Color.white)
                }
                .offset(x: 5, y: -1)
            Image(systemName: name)
                .resizable()
                .frame(width: 9, height: 9)
                .padding(2)
                .background {
                    Image(systemName: name)
                        .resizable()
                        .foregroundStyle(Color.white)
                }
                .offset(x: -2, y: -9)
        }
        .frame(width: 24, height: 32)
    }
    
    //TODO: Add setting to change water units
    @ViewBuilder private func Water() -> some View {
        if let waterGrams {
            let waterCups = Double(waterGrams) / 237
            
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(Color.blue)
                Text("Water")
                    .font(.subheadline)
                    .fontWeight(.light)
                Spacer()
                Text("\(waterCups.formatted(maxDigits: 1))cups")
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .contentTransition(.numericText())
            }
            .padding()
            .inCard()
        }
    }
    
    @ViewBuilder private func OtherStuff() -> some View {
        LazyVStack {
            ForEach(otherNutrientIds, id: \.self) { nutrientId in
                OtherCell(nutrientId)
            }
        }
    }
    
    @ViewBuilder private func OtherCell(_ nutrientId: String) -> some View {
        let nutrients = aggregator.nutrientsByNutrientNumber[nutrientId] ?? []
        
        let name = nutrients.first?.nutrient.name ?? "No Name"
        let unit = nutrients.first?.nutrient.unitName ?? "?"
        let amount = nutrients.reduce(0.0) { $0 + $1.nutrient.amount }
        
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(.light)
            Spacer()
            Text("\(amount.formatted(maxDigits: 0))\(unit)")
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .contentTransition(.numericText())
        }
        .padding()
        .inCard()
    }
}

#Preview {
    let sampleFoods = FoodItem.sampleFoods
    
    ScrollView {
        VStack {
            DashboardMacrosSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
    .scrollContentBackground(.hidden)
    .background(Color.accentColor.opacity(0.15).gradient)
}
