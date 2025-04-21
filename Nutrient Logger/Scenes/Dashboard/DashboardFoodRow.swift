//
//  DashboardFoodRow.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI

struct DashboardFoodRow: View {
    
    let food: ConsumedFood
    
    private func onFoodSaved(foodItem: FoodItem, portion: Portion) {
        food.portionAmount = portion.amount
        food.portionGramWeight = portion.gramWeight
        food.portionName = portion.name
        food.dateLogged = foodItem.dateLogged ?? food.dateLogged
        food.mealTime = foodItem.mealTime ?? food.mealTime
    }
    
    var body: some View {
        NavigationLink {
            FoodDetailsView(
                mode: .loggedFood(food: food),
                onFoodSaved: onFoodSaved
            )
        } label: {
            RowContent()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: .cornerRadiusListRow, style: .continuous)
                        .fill(.shadow(.drop(radius: .shadowRadiusDefault)))
                        .fill(Color.background.gradient)
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
            DashboardFoodRow(food: .dashboardSample)
        }
        .listDefaultModifiers()
    }
}
