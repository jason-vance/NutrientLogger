//
//  NutritionConcern.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/23/26.
//

import Foundation

/// What the user is most focused on, asked once during onboarding alongside `NutritionDietPreset`.
/// Promotes the nutrients most associated with that concern to the top of the Nutrition tab and is
/// stored on `User` for later reuse.
enum NutritionConcern: String, CaseIterable, Identifiable, Codable, Sendable {
    case generalHealth
    case energy
    case immunity
    case boneJoint
    case skinHairNails
    case heartHealth
    case muscleAthletic

    var id: String { rawValue }

    /// The default option — no personalization applied.
    static let `default`: NutritionConcern = .generalHealth

    /// Short label shown in the picker menu.
    var label: String {
        switch self {
        case .generalHealth: return "General health"
        case .energy: return "Energy"
        case .immunity: return "Immunity"
        case .boneJoint: return "Bone & joint"
        case .skinHairNails: return "Skin, hair & nails"
        case .heartHealth: return "Heart health"
        case .muscleAthletic: return "Muscle / athletic"
        }
    }

    /// One-line "we heard you" copy shown under the picker once selected.
    var reflectBack: String {
        switch self {
        case .generalHealth:
            return "We'll keep an eye on everything for you."
        case .energy:
            return "Low energy often ties back to iron, B12, and magnesium — we'll track them closely."
        case .immunity:
            return "For immune support we'll highlight Vitamin C, Vitamin D, and zinc."
        case .boneJoint:
            return "Strong bones need calcium, Vitamin D, and Vitamin K — we'll keep them up top."
        case .skinHairNails:
            return "Healthy skin and hair lean on Vitamin A, zinc, and Vitamin E — we'll track them."
        case .heartHealth:
            return "For heart health we'll track your omega-3s, potassium, and sodium."
        case .muscleAthletic:
            return "Building muscle, we'll surface your BCAAs plus iron and magnesium."
        }
    }

    /// Nutrients to pull to the top of each group, bucketed by group. IDs are `FdcNutrientGroupMapper`
    /// nutrient numbers. Empty for `.generalHealth`.
    var promotedNutrients: [CustomizableNutrientGroup: [String]] {
        switch self {
        case .generalHealth:
            return [:]
        case .energy:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminB6,
                    FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
                    FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                ],
            ]
        case .immunity:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
                    FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
                ],
            ]
        case .boneJoint:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                    FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                    FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P,
                ],
            ]
        case .skinHairNails:
            return [
                .vitamins: [
                    FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
                    FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol,
                ],
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
                    FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
                ],
            ]
        case .heartHealth:
            return [
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
                    FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                    FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
                ],
                .lipids: [
                    FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
                    FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA,
                    FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
                ],
            ]
        case .muscleAthletic:
            return [
                .minerals: [
                    FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
                    FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                    FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
                ],
                .aminoAcids: [
                    FdcNutrientGroupMapper.NutrientNumber_Leucine,
                    FdcNutrientGroupMapper.NutrientNumber_Isoleucine,
                    FdcNutrientGroupMapper.NutrientNumber_Valine,
                ],
            ]
        }
    }
}
