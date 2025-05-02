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

    let date: SimpleDate
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
    
    private var totalMacroCals: Double {
        return (4 * carbs) + (9 * fat) + (4 * protein)
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
    
    private var colorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_Proximates)
    }
    
    private var carbsColorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_Carbohydrates)
    }
    
    private var fatColorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_Lipids)
    }
    
    private var proteinColorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: FdcNutrientGroupMapper.GroupNumber_AminoAcids)
    }
    
    var body: some View {
        VStack(spacing: .spacingDefault) {
            CaloriesCard()
            CarbsFatProtein()
            Water()
            OtherStuff()
        }
    }
    
    @ViewBuilder private func CaloriesCard() -> some View {
        let lineWidthPts: CGFloat = 32
        
        NavigationLink {
            ConsumedMealsView(date: date)
        } label: {
            HStack {
                Spacer()
                GeometryReader { geometry in
                    ZStack {
                        if totalMacroCals > 0 {
                            let carbCals = carbs * 4
                            let fatCals = fat * 9
                            
                            //TODO: Make sure each section is rendered if value > 0
                            let circumference: CGFloat = geometry.size.width * .pi
                            let lineWidth: CGFloat = lineWidthPts / circumference
                            let margin: CGFloat = 8 / circumference
                            let carbStart: CGFloat = (lineWidth / 2) + (margin / 2)
                            let carbEnd = CGFloat(carbCals / totalMacroCals) - (lineWidth / 2) - (margin / 2)
                            let fatStart = carbEnd + lineWidth + margin
                            let fatEnd = CGFloat(fatCals / totalMacroCals) + fatStart - (lineWidth / 2) - (margin / 2)
                            let proteinStart = fatEnd + lineWidth + margin
                            let proteinEnd: CGFloat = 1 - (lineWidth / 2) - (margin / 2)
                            
                            Circle()
                                .trim(from: carbStart, to: carbEnd)
                                .stroke(style: .init(
                                    lineWidth: lineWidthPts,
                                    lineCap: .round
                                ))
                                .foregroundStyle(carbsColorPalette.accent)
                                .rotationEffect(.degrees(-90))
                            Circle()
                                .trim(from: fatStart, to: fatEnd)
                                .stroke(style: .init(
                                    lineWidth: lineWidthPts,
                                    lineCap: .round
                                ))
                                .foregroundStyle(fatColorPalette.accent)
                                .rotationEffect(.degrees(-90))
                            Circle()
                                .trim(from: proteinStart, to: proteinEnd)
                                .stroke(style: .init(
                                    lineWidth: lineWidthPts,
                                    lineCap: .round
                                ))
                                .foregroundStyle(proteinColorPalette.accent)
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
            .foregroundStyle(Color.text)
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }
    
    @ViewBuilder private func CarbsFatProtein() -> some View {
        HStack(spacing: .spacingDefault) {
            Macro(
                name: "Carbs",
                iconName: "square.fill",
                iconColor: carbsColorPalette.accent,
                amount: carbs,
                unit: carbsUnit,
                key: FdcNutrientGroupMapper.GroupNumber_Carbohydrates,
                detailHeaderText: "Carbohydrates"
            )
            Macro(
                name: "Fat",
                iconName: "circle.fill",
                iconColor: fatColorPalette.accent,
                amount: fat,
                unit: fatUnit,
                key: FdcNutrientGroupMapper.GroupNumber_Lipids,
                detailHeaderText: "Lipids"
            )
            Macro(
                name: "Protein",
                iconName: "triangle.fill",
                iconColor: proteinColorPalette.accent,
                amount: protein,
                unit: proteinUnit,
                key: FdcNutrientGroupMapper.GroupNumber_AminoAcids,
                detailHeaderText: "Amino Acids"
            )
        }
    }
    
    @ViewBuilder private func MacroDetail(title: String, headerText: String, key: String) -> some View {
        ScrollView {
            VStack {
                DashboardNutrientsSection(
                    blacklist: [],
                    orderedWhitelist: [],
                    groupKey: key,
                    headerText: headerText,
                    aggregator: aggregator
                )
            }
            .padding(.horizontal)
        }
        .navigationTitle(title)
    }
    
    @ViewBuilder private func Macro(
        name: String,
        iconName: String,
        iconColor: Color,
        amount: Double,
        unit: String,
        key: String,
        detailHeaderText: String
    ) -> some View {
        NavigationLink {
            MacroDetail(
                title: name,
                headerText: detailHeaderText,
                key: key
            )
        } label: {
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
            .foregroundStyle(Color.text)
            .padding(.vertical)
            .inCard(backgroundColor: Color.gray)
        }
    }
    
    @ViewBuilder private func MacroIcon(name: String) -> some View {
        ZStack {
            Image(systemName: name)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.background)
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(colorPalette.accent.opacity(.cardBackgroundColorOpacity).gradient)
                    }
                }
                .offset(x: -3, y: 6)
            Image(systemName: name)
                .resizable()
                .frame(width: 12, height: 12)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.background)
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(colorPalette.accent.opacity(.cardBackgroundColorOpacity).gradient)
                    }
                }
                .offset(x: 5, y: -1)
            Image(systemName: name)
                .resizable()
                .frame(width: 9, height: 9)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.background)
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(colorPalette.accent.opacity(.cardBackgroundColorOpacity).gradient)
                    }
                }
                .offset(x: -2, y: -9)
        }
        .frame(width: 24, height: 32)
    }
    
    //TODO: Add setting to change water units
    @ViewBuilder private func Water() -> some View {
        let waterCups = aggregator.waterCups
        
        NavigationLink {
            ConsumedWaterView(
                date: date,
                aggregator: aggregator
            )
        } label: {
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
            .foregroundStyle(Color.text)
            .padding()
            .inCard(backgroundColor: Color.gray)
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
        let nutrient = nutrients.first?.nutrient
        
        let name = nutrient?.name ?? "No Name"
        let unit = nutrient?.unitName ?? "?"
        let amount = nutrients.reduce(0.0) { $0 + $1.nutrient.amount }
        
        NavigationLink {
            if let nutrient {
                ConsumedNutrientDetailsView(
                    nutrient: nutrient,
                    nutrientFoodPairs: nutrients
                )
            } else {
                Text("Somehow `nutrient` is nil for \(nutrientId)")
            }
        } label: {
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
            .foregroundStyle(Color.text)
            .padding()
            .inCard(backgroundColor: Color.gray)
        }
    }
}

#Preview {
    let sampleFoods = FoodItem.sampleFoods
    
    ScrollView {
        VStack {
            DashboardMacrosSection(
                date: .today,
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
