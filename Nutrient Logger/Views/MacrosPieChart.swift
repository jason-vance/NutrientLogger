//
//  MacrosPieChart.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 1/15/26.
//

import SwiftUI

struct MacrosPieChart: View {
    
    struct ColorPalette {
        let carbs: Color
        let fat: Color
        let protein: Color
        
        init(carbs: Color = .indigo, fat: Color = .red, protein: Color = .green) {
            self.carbs = carbs
            self.fat = fat
            self.protein = protein
        }
    }
    
    struct Config {
        
        enum TotalLabelDisplay {
            case normal
            case abbreviated
            case none
        }
        
        let lineWidth: CGFloat
        let margin: CGFloat
        let totalLabelDisplay: TotalLabelDisplay
        let showFlameSymbol: Bool
        let caloriesFont: Font
        
        init(
            lineWidth: CGFloat = 32,
            margin: CGFloat = 8,
            totalLabelDisplay: TotalLabelDisplay = .normal,
            showFlameSymbol: Bool = true,
            caloriesFont: Font = .title
        ) {
            self.lineWidth = lineWidth
            self.margin = margin
            self.totalLabelDisplay = totalLabelDisplay
            self.showFlameSymbol = showFlameSymbol
            self.caloriesFont = caloriesFont
        }
    }
    
    let calories: Double
    let carbs: Double
    let fat: Double
    let protein: Double
    let colors: ColorPalette
    let config: Config
    
    init(
        calories: Double,
        carbs: Double,
        fat: Double,
        protein: Double,
        colors: ColorPalette = ColorPalette(),
        config: Config = Config()
    ) {
        self.calories = calories
        self.carbs = carbs
        self.fat = fat
        self.protein = protein
        self.colors = colors
        self.config = config
    }
    
    private var totalMacroCals: Double {
        return (4 * carbs) + (9 * fat) + (4 * protein)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if totalMacroCals > 0 {
                    let carbCals = carbs * 4
                    let fatCals = fat * 9
                    
                    //TODO: Make sure each section is rendered if value > 0
                    let circumference: CGFloat = geometry.size.width * .pi
                    let lineWidth: CGFloat = config.lineWidth / circumference
                    let margin: CGFloat = config.margin / circumference
                    let carbStart: CGFloat = (lineWidth / 2) + (margin / 2)
                    let carbEnd = CGFloat(carbCals / totalMacroCals) - (lineWidth / 2) - (margin / 2)
                    let fatStart = carbEnd + lineWidth + margin
                    let fatEnd = CGFloat(fatCals / totalMacroCals) + fatStart - lineWidth - margin
                    let proteinStart = fatEnd + lineWidth + margin
                    let proteinEnd: CGFloat = 1 - (lineWidth / 2) - (margin / 2)
                    
                    Circle()
                        .trim(from: carbStart, to: carbEnd)
                        .stroke(style: .init(
                            lineWidth: config.lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(colors.carbs)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: fatStart, to: fatEnd)
                        .stroke(style: .init(
                            lineWidth: config.lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(colors.fat)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: proteinStart, to: proteinEnd)
                        .stroke(style: .init(
                            lineWidth: config.lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(colors.protein)
                        .rotationEffect(.degrees(-90))
                } else {
                    Circle()
                        .stroke(style: .init(
                            lineWidth: config.lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(Color.gray)
                }
                VStack {
                    if config.totalLabelDisplay != .none {
                        Text(config.totalLabelDisplay == .normal ? "Total Calories" : "Cals")
                            .font(.headline)
                            .fontWeight(.light)
                    }
                    HStack {
                        if config.showFlameSymbol {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.orange)
                        }
                        Text("\(calories.formatted(maxDigits: 0))")
                            .contentTransition(.numericText())
                    }
                    .font(config.caloriesFont)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                }
                .offset(y: config.totalLabelDisplay != .none ? -5 : 0)
            }
        }
        .padding(config.lineWidth / 2)
    }
}

#Preview {
    MacrosPieChart(
        calories: 1250,
        carbs: 100,
        fat: 50,
        protein: 100
    )
    .frame(width: 282, height: 282)
    MacrosPieChart(
        calories: 1250,
        carbs: 100,
        fat: 50,
        protein: 100,
        config: MacrosPieChart.Config(
            lineWidth: 16,
            margin: 4,
            totalLabelDisplay: .abbreviated,
            showFlameSymbol: false,
            caloriesFont: .title
        )
    )
    .frame(width: 128, height: 128)
}
