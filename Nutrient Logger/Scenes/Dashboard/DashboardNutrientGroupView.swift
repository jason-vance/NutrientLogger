//
//  DashboardNutrientGroupView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/29/25.
//

import SwiftUI

struct DashboardNutrientGroupView: View {
    
    let nutrientGroup: NutrientGroup
    let aggregator: NutrientDataAggregator

    private let columns: [GridItem] = Array(repeating: GridItem(.adaptive(minimum: 100)), count: 2)
    
    var body: some View {
        let nutrients = Nutrient.sortNutrients(nutrientGroup.nutrients)
        let fdcNumbers = Set(nutrients.map(\.fdcNumber))
        
        HStack {
            Text(nutrientGroup.name)
                .listSubsectionHeader()
            Spacer()
        }
        .padding(.top, 4)
        
        LazyVGrid(columns: columns) {
            ForEach(fdcNumbers.sorted(), id: \.self) { fdcNumber in
                DashboardNutrientCell(nutrients: aggregator.nutrientsByNutrientNumber[fdcNumber] ?? [])
            }
        }
    }
}

#Preview {
    let food = try! RemoteDatabaseForScreenshots().getFood("asdf")!
    let aggregator = NutrientDataAggregator([food])

    DashboardNutrientGroupView(
        nutrientGroup: aggregator.nutrientGroups[0],
        aggregator: aggregator
    )
}
