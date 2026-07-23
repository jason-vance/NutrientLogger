//
//  NutritionDietPreset.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// The diet the user follows, asked once during onboarding. Drives which nutrients get promoted to
/// the top of the Nutrition tab (see `NutritionPersonalizationPlan`) and is stored on `User` for
/// later reuse. The nutrient sets lean toward what each diet tends to run *short* on.
enum NutritionDietPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case balanced
    case plantBased
    case ketoLowCarb
    case carnivore
    case pescatarian

    var id: String { rawValue }

    /// The default option — no personalization applied.
    static let `default`: NutritionDietPreset = .balanced

    /// Short label shown in the picker menu.
    var label: String {
        switch self {
        case .balanced: return "Balanced"
        case .plantBased: return "Plant-based"
        case .ketoLowCarb: return "Keto / Low-carb"
        case .carnivore: return "Carnivore"
        case .pescatarian: return "Pescatarian"
        }
    }

    /// One-line "we heard you" copy shown under the picker once selected.
    var reflectBack: String {
        switch self {
        case .balanced:
            return "We'll track all 30+ nutrients for you."
        case .plantBased:
            return "Plant-based eaters most often run low on B12, iron, and zinc — we'll keep them front and center."
        case .ketoLowCarb:
            return "Low-carb diets can run short on electrolytes — we'll watch your magnesium, potassium, and sodium."
        case .carnivore:
            return "Carnivore is rich in B12 and zinc but can lack Vitamin C, folate, and manganese — we'll flag those."
        case .pescatarian:
            return "Great omega-3s — we'll keep an eye on the iron and zinc from the meat you're skipping."
        }
    }

    /// Nutrients to pull to the top of each group, bucketed by group. IDs are `FdcNutrientGroupMapper`
    /// nutrient numbers. Empty for `.balanced`.
    var promotedNutrients: [CustomizableNutrientGroup: [String]] {
        switch self {
        case .balanced:
            return [:]
        case .plantBased:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
                    FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
                    FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                ],
                .lipids: [
                    FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
                    FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
                    FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA,
                ],
            ]
        case .ketoLowCarb:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
                    FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                    FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
                    FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
                ],
            ]
        case .carnivore:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
                    FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn,
                    FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                ],
            ]
        case .pescatarian:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
                    FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
                ],
            ]
        }
    }
}
