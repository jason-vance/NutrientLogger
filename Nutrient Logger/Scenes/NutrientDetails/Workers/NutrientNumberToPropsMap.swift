//
//  NutrientNumberToPropsMap.swift
//  NutrientNumberToPropsMap
//
//  Created by Jason Vance on 9/13/21.
//

import Foundation

public class NutrientNumberToPropsMap {
    public class PostLoadRule {
        public var applyTo: (NutrientExplanation) -> Void
        
        public init(_ applyTo: @escaping (NutrientExplanation) -> Void) {
            self.applyTo = applyTo
        }
    }

    public class ExplanationProps {
        public var url: String
        public var postLoadRules = [PostLoadRule]()
        
        public init(url: String) {
            self.url = url
            
            postLoadRules.append(PostLoadRule({ (exp: NutrientExplanation) in
                exp.sections.removeLast()
            }))
        }
    }

    private static let VitaminA = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminA-Consumer/"
    )
    private static let Thiamin = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Thiamin-Consumer/"
    )
    private static let VitaminB12 = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminB12-Consumer/"
    )
    private static let Riboflavin = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Riboflavin-Consumer/"
    )
    private static let Niacin = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Niacin-Consumer/"
    )
    private static let PantothenicAcid = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/PantothenicAcid-Consumer/"
    )
    private static let VitaminB6 = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminB6-Consumer/"
    )
    private static let Biotin = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Biotin-Consumer/"
    )
    private static let Folate = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Folate-Consumer/"
    )
    private static let VitaminC = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminC-Consumer/"
    )
    private static let VitaminD = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminD-Consumer/"
    )
    private static let VitaminE = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminE-Consumer/"
    )
    private static let VitaminK = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/VitaminK-Consumer/"
    )
    private static let Choline = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Choline-Consumer/"
    )
    private static let Omega3FattyAcids = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Omega3FattyAcids-Consumer/"
    )
    private static let Boron = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Boron-Consumer/"
    )
    private static let Calcium = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Calcium-Consumer/"
    )
    private static let Chromium = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Chromium-Consumer/"
    )
    private static let Copper = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Copper-Consumer/"
    )
    private static let Fluoride = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Fluoride-Consumer/"
    )
    private static let Iodine = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Iodine-Consumer/"
    )
    private static let Iron = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Iron-Consumer/"
    )
    private static let Magnesium = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Magnesium-Consumer/"
    )
    private static let Manganese = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Manganese-Consumer/"
    )
    private static let Molybdenum = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Molybdenum-Consumer/"
    )
    private static let Phosphorus = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Phosphorus-Consumer/"
    )
    private static let Potassium = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Potassium-Consumer/"
    )
    private static let Selenium = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Selenium-Consumer/"
    )
    private static let Zinc = ExplanationProps (
        url: "https://ods.od.nih.gov/factsheets/Zinc-Consumer/"
    )
    
    public static func containsKey(_ key: String) -> Bool {
        return numberToPropsMap.keys.contains(key)
    }
    
    public static subscript(_ key: String) -> ExplanationProps? {
        return numberToPropsMap[key]
    }

    private static let numberToPropsMap: [String: ExplanationProps] = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU: VitaminA,
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE: VitaminA,
        FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta: VitaminA,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta: VitaminA,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta: VitaminA,
        FdcNutrientGroupMapper.NutrientNumber_Retinol: VitaminA,

        FdcNutrientGroupMapper.NutrientNumber_Thiamin: Thiamin,

        FdcNutrientGroupMapper.NutrientNumber_VitaminB12: VitaminB12,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12_Added: VitaminB12,

        FdcNutrientGroupMapper.NutrientNumber_Riboflavin: Riboflavin,

        FdcNutrientGroupMapper.NutrientNumber_Niacin: Niacin,

        FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid: PantothenicAcid,

        FdcNutrientGroupMapper.NutrientNumber_VitaminB6: VitaminB6,

        FdcNutrientGroupMapper.NutrientNumber_Biotin: Biotin,

        FdcNutrientGroupMapper.NutrientNumber_Folate_DFE: Folate,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Food: Folate,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Total: Folate,

        FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid: VitaminC,

        FdcNutrientGroupMapper.NutrientNumber_VitaminD3_Cholecalciferol: VitaminD,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2: VitaminD,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3: VitaminD,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU: VitaminD,

        FdcNutrientGroupMapper.NutrientNumber_VitaminE: VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Added: VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol: VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_LabelEntryPrimarily: VitaminE,

        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Dihydrophylloquinone: VitaminK,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Menaquinone_4: VitaminK,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone: VitaminK,

        FdcNutrientGroupMapper.NutrientNumber_Choline_Free: Choline,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromGlycerophosphocholine: Choline,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphocholine: Choline,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphotidylCholine: Choline,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromSphingomyelin: Choline,
        FdcNutrientGroupMapper.NutrientNumber_Choline_Total: Choline,

        FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA: Omega3FattyAcids,
        FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA: Omega3FattyAcids,
        FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA: Omega3FattyAcids,

        FdcNutrientGroupMapper.NutrientNumber_Boron_B: Boron,
        FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca: Calcium,
        FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr: Chromium,
        FdcNutrientGroupMapper.NutrientNumber_Copper_Cu: Copper,
        FdcNutrientGroupMapper.NutrientNumber_Fluoride_F: Fluoride,
        FdcNutrientGroupMapper.NutrientNumber_Iodine_I: Iodine,
        FdcNutrientGroupMapper.NutrientNumber_Iron_Fe: Iron,
        FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg: Magnesium,
        FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn: Manganese,
        FdcNutrientGroupMapper.NutrientNumber_Molybdenum_Mo: Molybdenum,
        FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P: Phosphorus,
        FdcNutrientGroupMapper.NutrientNumber_Potassium_K: Potassium,
        FdcNutrientGroupMapper.NutrientNumber_Selenium_Se: Selenium,
        FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn: Zinc
    ]
}
