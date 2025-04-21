//
//  DashboardNutrientCell.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: Add various styles/sizes of row
struct DashboardNutrientCell: View {
    
    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary
    
    let nutrients: [NutrientFoodPair]
    
    var name: String { nutrients[0].nutrient.name }
    var units: String { nutrients[0].nutrient.unitName }
    var fdcNumber: String { nutrients[0].nutrient.fdcNumber }
    
    var currentAmount: Double { nutrients.reduce(0.0) { $0 + $1.nutrient.amount } }
    
    var colorPalette: ColorPalette {
        let groupNumber = FdcNutrientGroupMapper.groupNumberForNutrient(fdcNumber)
        return ColorPaletteService.getColorPaletteFor(number: groupNumber)
    }
    
    var body: some View {
        NavigationLink {
            ConsumedNutrientDetailsView(
                nutrient: nutrients.first!.nutrient,
                nutrientFoodPairs: nutrients
            )
        } label: {
            RowContent()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                        .fill(.shadow(.drop(radius: .shadowRadiusDefault)))
                        .fill(colorPalette.background.gradient)
                }
        }
        .listRowDefaultModifiers()
        .foregroundStyle(colorPalette.text)
    }
    
    @ViewBuilder private func RowContent() -> some View {
        ZStack(alignment: .top) {
            ConsumedNutrientChart(
                nutrientFoodPairs: nutrients,
                rdi: nil,
                style: .cumulative
            )
            .frame(height: 80)
            .foregroundStyle(colorPalette.accent.gradient)
            .offset(y: 40)
            VStack {
                HStack(spacing: 0) {
                    Text(name)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .font(.headline)
                HStack(spacing: 0) {
                    Text(currentAmount.formatted(maxDigits: 2))
                    Text(units)
                    Spacer()
                }
                .font(.callout)
                Spacer()
            }
        }
        .frame(height: 120)
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!

    NavigationStack {
        ScrollView {
            DashboardNutrientSection(foods: [food])
        }
    }
}
