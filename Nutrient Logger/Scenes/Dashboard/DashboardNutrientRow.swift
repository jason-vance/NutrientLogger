//
//  DashboardNutrientRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

struct DashboardNutrientRow: View {
    
    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary
    
    let nutrients: [NutrientFoodPair]
    
    var name: String { nutrients[0].nutrient.name }
    var units: String { nutrients[0].nutrient.unitName }
    var fdcNumber: String { nutrients[0].nutrient.fdcNumber }
    
    var currentAmount: Double { nutrients.reduce(0.0) { $0 + $1.nutrient.amount } }
    
    var body: some View {
        NavigationLink {
            ConsumedNutrientDetailsView(
                nutrient: nutrients.first!.nutrient,
                nutrientFoodPairs: nutrients
            )
        } label: {
            RowContent()
        }
        .listRowDefaultModifiers()
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background {
            //TODO: MVP: Background is flashing when appearing
            RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                .fill(.shadow(.drop(radius: .shadowRadiusDefault)))
                .fill(.white)
                
        }
    }
    
    @ViewBuilder private func RowContent() -> some View {
        VStack {
            HStack(spacing: 0) {
                Text(name)
                    .font(.callout)
                Spacer()
                Text(currentAmount.formatted(maxDigits: 2))
                    .font(.headline)
                Text(units)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(AdProvider.self) { MockAdProvider() }

    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!

    NavigationStack {
        List {
            DashboardNutrientSection(foods: [food])
        }
        .listDefaultModifiers()
    }
}
