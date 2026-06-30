//
//  DashboardMacrosSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/29/25.
//

import SwiftUI

struct DashboardMacrosSection: View {

    @Inject private var userService: UserService

    let date: SimpleDate
    let aggregator: NutrientDataAggregator

    private var user: User { userService.currentUser }
    
    private var totalMacroCals: Double {
        return (4 * aggregator.carbs) + (9 * aggregator.fat) + (4 * aggregator.protein)
    }
    
    private var otherNutrientIds: [String] {
        let proximatesNum = FdcNutrientGroupMapper.GroupNumber_Proximates
        
        guard let proximates = aggregator.nutrientGroups
            .first(where: { $0.fdcNumber == proximatesNum })
        else {
            return []
        }
        
        let dontInclude = [
            FdcNutrientGroupMapper.NutrientNumber_Energy_KCal,
            FdcNutrientGroupMapper.NutrientNumber_Protein,
            FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat,
            FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference,
            FdcNutrientGroupMapper.NutrientNumber_Water,
            FdcNutrientGroupMapper.NutrientNumber_Energy_Kj,
            FdcNutrientGroupMapper.NutrientNumber_Ash
        ]
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
                ZStack {
                    MacrosPieChart(
                        calories: aggregator.calories,
                        calorieGoal: user.calorieGoal,
                        carbs: aggregator.carbs,
                        fat: aggregator.fat,
                        protein: aggregator.protein
                    )
                    CalorieGoalRing(
                        calories: aggregator.calories,
                        calorieGoal: user.calorieGoal
                    )
                    .padding(lineWidthPts + 6)
                }
                .aspectRatio(1, contentMode: .fit)
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
                amount: aggregator.carbs,
                unit: aggregator.carbsUnit,
                goal: user.carbsGoalGrams,
                key: FdcNutrientGroupMapper.GroupNumber_Carbohydrates,
                detailHeaderText: "Carbohydrates"
            )
            Macro(
                name: "Fat",
                iconName: "circle.fill",
                iconColor: fatColorPalette.accent,
                amount: aggregator.fat,
                unit: aggregator.fatUnit,
                goal: user.fatGoalGrams,
                key: FdcNutrientGroupMapper.GroupNumber_Lipids,
                detailHeaderText: "Lipids"
            )
            Macro(
                name: "Protein",
                iconName: "triangle.fill",
                iconColor: proteinColorPalette.accent,
                amount: aggregator.protein,
                unit: aggregator.proteinUnit,
                goal: user.proteinGoalGrams,
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
        goal: Double?,
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
                if let goal {
                    ProgressView(value: min(amount / goal, 1.0))
                        .tint(iconColor)
                        .padding(.horizontal, 8)
                    Text("of \(goal.formatted(maxDigits: 0))\(unit)")
                        .font(.caption2)
                        .fontWeight(.light)
                        .contentTransition(.numericText())
                }
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
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }

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
