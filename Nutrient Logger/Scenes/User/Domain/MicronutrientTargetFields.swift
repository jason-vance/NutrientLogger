//
//  MicronutrientTargetFields.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 8/24/26.
//

import Foundation

/// Which nutrients the Micronutrient Targets screen offers a goal and upper limit for, per section.
///
/// This is deliberately not just `CustomFood.formFields` grouped by `group`: that list is laid out
/// the way a nutrition label reads, which is right for the custom food form and the barcode review
/// but puts sodium under the macros. As a *target* sodium belongs with the minerals — it's the one
/// people most often want to cap, and the Sodium : Potassium balance leans on it.
enum MicronutrientTargetFields {

    static func fields(forGroup group: String) -> [CustomFood.FormField] {
        group == "Minerals" ? minerals : CustomFood.formFields.filter { $0.group == group }
    }

    /// The mineral group plus sodium, slotted in next to potassium so the pair reads together.
    static let minerals: [CustomFood.FormField] = {
        var fields = CustomFood.formFields.filter { $0.group == "Minerals" }

        guard let sodium = CustomFood.formFields.first(where: {
            $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Sodium_Na
        }) else { return fields }

        let potassiumIndex = fields.firstIndex {
            $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Potassium_K
        }
        fields.insert(sodium, at: potassiumIndex.map { $0 + 1 } ?? fields.count)
        return fields
    }()
}
