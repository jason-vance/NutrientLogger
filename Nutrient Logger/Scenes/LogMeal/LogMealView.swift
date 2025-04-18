//
//  LogMealView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import SwiftUI

//TODO: MVP: Implement this
struct LogMealView: View {
    
    let meal: Meal
    
    var body: some View {
        List {
            ForEach(meal.foodsWithPortions) { foodWithPortion in
                FoodRow(foodWithPortion)
            }
        }
        .listDefaultModifiers()
    }
    
    @ViewBuilder private func FoodRow(_ foodWithPortion: Meal.FoodWithPortion) -> some View {
        VStack {
            HStack {
                Text(foodWithPortion.foodName)
                Spacer()
            }
            .bold()
            HStack {
                Text("\(foodWithPortion.portionAmount.formatted(maxDigits: 2)) \(foodWithPortion.portionName)")
                Spacer()
            }
            .font(.footnote)
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    NavigationStack {
        LogMealView(meal: .sample)
    }
}
