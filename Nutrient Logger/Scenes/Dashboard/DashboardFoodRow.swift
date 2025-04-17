//
//  DashboardFoodRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI

struct DashboardFoodRow: View {
    
    let food: ConsumedFood
    
    var body: some View {
        NavigationLink {
            FoodDetailsView(
                mode: .loggedFood(food: food),
                onFoodSaved: { _,_ in assertionFailure("Should not be called") }
            )
        } label: {
            RowContent()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                        .fill(.shadow(.drop(radius: .shadowRadiusDefault)))
                        .fill(.white)
                    
                }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func RowContent() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.headline)
                Text("\(food.portionAmount.formatted()) \(food.portionName)")
                    .font(.callout)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        List {
            DashboardFoodRow(food: .dashboardSample)
        }
        .listDefaultModifiers()
    }
}
