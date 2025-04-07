//
//  FdcNutrientGrouper.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import Foundation

public class FdcNutrientGrouper {

    public static func group(_ nutrients: [Nutrient]) -> [NutrientGroup] {
        var groups = [String:NutrientGroup]()

        for nutrient in nutrients {
            let groupNumber = addGroupIfNecessary(&groups, nutrient.fdcNumber)
            groups[groupNumber]!.nutrients.append(nutrient)
        }

        return groups.values.sorted { $0.rank < $1.rank }
    }

    private static func addGroupIfNecessary(_ groups: inout [String:NutrientGroup], _ nutrientNumber: String) -> String {
        let groupNumber = FdcNutrientGroupMapper.groupNumberForNutrient(nutrientNumber)

        if (!groups.keys.contains(groupNumber)) {
            groups[groupNumber] = FdcNutrientGroupMapper.makeGroupNutrient(groupNumber)
        }

        return groupNumber
    }
}
