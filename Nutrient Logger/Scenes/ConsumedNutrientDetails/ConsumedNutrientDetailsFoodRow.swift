//
//  ConsumedNutrientDetailsFoodRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import SwiftUI

struct ConsumedNutrientDetailsFoodRow: View {
    
    let nutrientNumber: String
    let food: FoodItem
    
    private var nutrient: Nutrient? {
        return food.nutrientGroups
            .reduce(into: []) { result, group in result += group.nutrients }
            .first(where: { $0.fdcNumber == nutrientNumber })
    }
    
    var body: some View {
        RowContent()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func RowContent() -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(food.name)
                        .font(.headline)
                    Spacer()
                    if let nutrient {
                        Text("\(nutrient.amount.formatted(maxDigits: 2))\(nutrient.unitName)")
                    }
                }
                Text("\(food.amount.formatted()) \(food.portionName)")
                    .font(.footnote)
            }
            Spacer()
        }
        .foregroundStyle(Color.text)
    }
}

#Preview {
    NavigationStack {
        List {
            ConsumedNutrientDetailsFoodRow(
                nutrientNumber: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                food: .dashboardSample
            )
        }
        .listDefaultModifiers()
    }
}
