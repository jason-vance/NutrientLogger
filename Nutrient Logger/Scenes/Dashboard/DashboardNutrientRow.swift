//
//  DashboardNutrientRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwinjectAutoregistration

struct DashboardNutrientRow: View {
    
    private let userService = swinjectContainer~>UserService.self
    private let rdiLibrary = swinjectContainer~>NutrientRdiLibrary.self
    
    let nutrients: [NutrientFoodPair]
    
    var name: String { nutrients[0].nutrient.name }
    var units: String { nutrients[0].nutrient.unitName }
    var fdcNumber: String { nutrients[0].nutrient.fdcNumber }
    
    var currentAmount: Double { nutrients.reduce(0.0) { $0 + $1.nutrient.amount } }
    
    var body: some View {
        NavigationLink {
            //TODO: MVP: Navigate somewhere real
            Text("Nutrient Details")
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
    
    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!

    List {
        DashboardNutrientSection(foods: [food])
    }
    .listDefaultModifiers()
}
