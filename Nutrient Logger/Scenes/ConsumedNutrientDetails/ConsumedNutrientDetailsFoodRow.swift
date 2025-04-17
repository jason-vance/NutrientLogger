//
//  ConsumedNutrientDetailsFoodRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import SwiftUI

struct ConsumedNutrientDetailsFoodRow: View {
    
    let food: FoodItem
    
    var body: some View {
        RowContent()
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                    .fill(.shadow(.drop(radius: .shadowRadiusDefault)))
                    .fill(.white)
                
            }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func RowContent() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.headline)
                Text("\(food.amount.formatted()) \(food.portionName)")
                    .font(.callout)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ConsumedNutrientDetailsFoodRow(food: .dashboardSample)
        }
        .listDefaultModifiers()
    }
}
