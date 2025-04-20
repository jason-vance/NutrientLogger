//
//  FdcNutrientGroupMapper.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import Foundation

class FdcNutrientGroupMapper {
    public static let GroupNumber_Other = "-1"
    public static let GroupNumber_Proximates = "951"
    public static let GroupNumber_AminoAcids = "500"
    public static let GroupNumber_Carbohydrates = "956"
    public static let GroupNumber_Minerals = "300"
    public static let GroupNumber_VitaminsAndOtherComponents = "952"
    public static let GroupNumber_Lipids = "950"
    
    
    public static let NutrientNumber_FattyAcids_TotalSaturated = "606"
    public static let NutrientNumber_4_0 = "607"
    public static let NutrientNumber_5_0 = "632"
    public static let NutrientNumber_6_0 = "608"
    public static let NutrientNumber_7_0 = "633"
    public static let NutrientNumber_8_0 = "609"
    public static let NutrientNumber_9_0 = "634"
    public static let NutrientNumber_10_0 = "610"
    public static let NutrientNumber_11_0 = "699"
    public static let NutrientNumber_12_0 = "611"
    public static let NutrientNumber_13_0 = "696"
    public static let NutrientNumber_14_0 = "612"
    public static let NutrientNumber_15_0 = "652"
    public static let NutrientNumber_16_0 = "613"
    public static let NutrientNumber_17_0 = "653"
    public static let NutrientNumber_18_0 = "614"
    public static let NutrientNumber_20_0 = "615"
    public static let NutrientNumber_21_0 = "681"
    public static let NutrientNumber_22_0 = "624"
    public static let NutrientNumber_23_0 = "682"
    public static let NutrientNumber_24_0 = "654"
    public static let NutrientNumber_FattyAcids_TotalMonounsaturated = "645"
    public static let NutrientNumber_12_1 = "635"
    public static let NutrientNumber_14_1 = "625"
    public static let NutrientNumber_14_1_T = "821"
    public static let NutrientNumber_14_1_C = "822"
    public static let NutrientNumber_15_1 = "697"
    public static let NutrientNumber_16_1 = "626"
    public static let NutrientNumber_16_1_C = "673"
    public static let NutrientNumber_17_1 = "687"
    public static let NutrientNumber_17_1_C = "825"
    public static let NutrientNumber_18_1 = "617"
    public static let NutrientNumber_18_1_C = "674"
    public static let NutrientNumber_18_1_11_t_18_1t_n_7 = "859"
    public static let NutrientNumber_20_1 = "628"
    public static let NutrientNumber_20_1_C = "829"
    public static let NutrientNumber_20_1_T = "830"
    public static let NutrientNumber_22_1 = "630"
    public static let NutrientNumber_22_1_C = "676"
    public static let NutrientNumber_22_1_N_9 = "676.1"
    public static let NutrientNumber_22_1_N_11 = "676.2"
    public static let NutrientNumber_24_1_C = "671"
    public static let NutrientNumber_FattyAcids_TotalPolyunsaturated = "646"
    public static let NutrientNumber_18_2 = "618"
    public static let NutrientNumber_18_2_I = "666"
    public static let NutrientNumber_18_2_C = "831"
    public static let NutrientNumber_18_2_N_6_C_C = "675"
    public static let NutrientNumber_18_2_CLAs = "670"
    public static let NutrientNumber_18_3 = "619"
    public static let NutrientNumber_18_3_C = "833"
    public static let NutrientNumber_18_3_T = "834"
    public static let NutrientNumber_18_3_I = "856"
    public static let NutrientNumber_18_3_N_3_C_C_C_ALA = "851"
    public static let NutrientNumber_18_3_N_6_C_C_C = "685"
    public static let NutrientNumber_18_4 = "627"
    public static let NutrientNumber_20_2_C = "840"
    public static let NutrientNumber_20_2_N_6_C_C = "672"
    public static let NutrientNumber_20_3 = "689"
    public static let NutrientNumber_20_3_C = "835"
    public static let NutrientNumber_20_3_N_3 = "852"
    public static let NutrientNumber_20_3_N_6 = "853"
    public static let NutrientNumber_20_3_N_9 = "861"
    public static let NutrientNumber_20_4 = "620"
    public static let NutrientNumber_20_4_C = "836"
    public static let NutrientNumber_20_4_N_6 = "855"
    public static let NutrientNumber_20_5_C = "837"
    public static let NutrientNumber_20_5_N_3_EPA = "629"
    public static let NutrientNumber_21_5 = "857"
    public static let NutrientNumber_22_2 = "698"
    public static let NutrientNumber_22_3 = "683"
    public static let NutrientNumber_22_4 = "858"
    public static let NutrientNumber_22_5_C = "838"
    public static let NutrientNumber_22_5_N_3_DPA = "631"
    public static let NutrientNumber_22_6_C = "839"
    public static let NutrientNumber_22_6_N_3_DHA = "621"
    public static let NutrientNumber_FattyAcids_TotalTrans = "605"
    public static let NutrientNumber_FattyAcids_TotalTrans_Monoenoic = "693"
    public static let NutrientNumber_FattyAcids_TotalTrans_PolyEnoic = "695"
    public static let NutrientNumber_16_1_T = "662"
    public static let NutrientNumber_18_1_T = "663"
    public static let NutrientNumber_22_1_T = "664"
    public static let NutrientNumber_FattyAcids_TotalTrans_Dienoic = "694"
    public static let NutrientNumber_18_2_T_NotFurtherDefined = "665"
    public static let NutrientNumber_18_2_T_T = "669"
    public static let NutrientNumber_Cholesterol = "601"
    public static let NutrientNumber_Phytosterols = "636"
    public static let NutrientNumber_PhytosterolsOther = "651"
    public static let NutrientNumber_Stigmasterol = "638"
    public static let NutrientNumber_Campesterol = "639"
    public static let NutrientNumber_Brassicasterol = "640"
    public static let NutrientNumber_Beta_Sitosterol = "641"
    public static let NutrientNumber_Campestanol = "642"
    public static let NutrientNumber_Beta_Sitostanol = "647"
    public static let NutrientNumber_Delta5Avenasterol = "649"
    
    public static let NutrientNumber_VitaminC_TotalAscorbicAcid = "401"
    public static let NutrientNumber_Thiamin = "404"
    public static let NutrientNumber_Riboflavin = "405"
    public static let NutrientNumber_Niacin = "406"
    public static let NutrientNumber_PantothenicAcid = "410"
    public static let NutrientNumber_VitaminB6 = "415"
    public static let NutrientNumber_Choline_Total = "421"
    public static let NutrientNumber_Choline_Free = "450"
    public static let NutrientNumber_Choline_FromPhosphocholine = "451"
    public static let NutrientNumber_Choline_FromPhosphotidylCholine = "452"
    public static let NutrientNumber_Choline_FromGlycerophosphocholine = "453"
    public static let NutrientNumber_Choline_FromSphingomyelin = "455"
    public static let NutrientNumber_Betaine = "454"
    public static let NutrientNumber_VitaminB12 = "418"
    public static let NutrientNumber_VitaminA_IU = "318"
    public static let NutrientNumber_Retinol = "319"
    public static let NutrientNumber_VitaminA_RAE = "320"
    public static let NutrientNumber_Carotene_Beta = "321"
    public static let NutrientNumber_Cis_Carotene_Beta = "321.1"
    public static let NutrientNumber_Trans_Carotene_Beta = "321.2"
    public static let NutrientNumber_Carotene_Alpha = "322"
    public static let NutrientNumber_Cryptoxanthin_Beta = "334"
    public static let NutrientNumber_Cryptoxanthin_Alpha = "335"
    public static let NutrientNumber_Lycopene = "337"
    public static let NutrientNumber_Cis_Lycopene = "337.1"
    public static let NutrientNumber_Trans_Lycopene = "337.2"
    public static let NutrientNumber_Lutein_Zeaxanthin = "338"
    public static let NutrientNumber_Lutein = "338.1"
    public static let NutrientNumber_Zeaxanthin = "338.2"
    public static let NutrientNumber_Cis_Lutein_Zeaxanthin = "338.3"
    public static let NutrientNumber_VitaminE_Added = "573"
    public static let NutrientNumber_VitaminE_Alpha_Tocopherol = "323"
    public static let NutrientNumber_VitaminE_LabelEntryPrimarily = "340"
    public static let NutrientNumber_VitaminE = "394"
    public static let NutrientNumber_Tocopherol_Beta = "341"
    public static let NutrientNumber_Tocopherol_Gamma = "342"
    public static let NutrientNumber_Tocopherol_Delta = "343"
    public static let NutrientNumber_Tocotrienol_Alpha = "344"
    public static let NutrientNumber_Tocotrienol_Beta = "345"
    public static let NutrientNumber_Tocotrienol_Gamma = "346"
    public static let NutrientNumber_Tocotrienol_Delta = "347"
    public static let NutrientNumber_VitaminK_Menaquinone_4 = "428"
    public static let NutrientNumber_VitaminK_Dihydrophylloquinone = "429"
    public static let NutrientNumber_VitaminK_Phylloquinone = "430"
    public static let NutrientNumber_FolicAcid = "431"
    public static let NutrientNumber_FormylFolicAcid = "436"
    public static let NutrientNumber_FormylTetrahyrdofolicAcid = "437"
    public static let NutrientNumber_Folate_Total = "417"
    public static let NutrientNumber_Folate_Food = "432"
    public static let NutrientNumber_MethylTetrahydrofolate = "433"
    public static let NutrientNumber_Folate_DFE = "435"
    public static let NutrientNumber_VitaminD_D2_Plus_D3_IU = "324"
    public static let NutrientNumber_VitaminD_D2 = "325"
    public static let NutrientNumber_VitaminD3_Cholecalciferol = "326"
    public static let NutrientNumber_Hydroxycholecalciferol = "327"
    public static let NutrientNumber_VitaminD_D2_Plus_D3 = "328"
    public static let NutrientNumber_VitaminB12_Added = "578"
    public static let NutrientNumber_Caffeine = "262"
    public static let NutrientNumber_Theobromine = "263"
    public static let NutrientNumber_Biotin = "416"
    public static let NutrientNumber_Phytoene = "330"
    public static let NutrientNumber_Phytofluene = "331"
    public static let NutrientNumber_Epigallocatechin3Gallate = "753"
    
    public static let NutrientNumber_Tryptophan = "501"
    public static let NutrientNumber_Threonine = "502"
    public static let NutrientNumber_Isoleucine = "503"
    public static let NutrientNumber_Leucine = "504"
    public static let NutrientNumber_Lysine = "505"
    public static let NutrientNumber_Methionine = "506"
    public static let NutrientNumber_Cystine = "507"
    public static let NutrientNumber_Phenylalanine = "508"
    public static let NutrientNumber_Tyrosine = "509"
    public static let NutrientNumber_Valine = "510"
    public static let NutrientNumber_Arginine = "511"
    public static let NutrientNumber_Histidine = "512"
    public static let NutrientNumber_Alanine = "513"
    public static let NutrientNumber_AsparticAcid = "514"
    public static let NutrientNumber_GlutamicAcid = "515"
    public static let NutrientNumber_Glycine = "516"
    public static let NutrientNumber_Proline = "517"
    public static let NutrientNumber_Serine = "518"
    public static let NutrientNumber_Hydroxyproline = "521"
    public static let NutrientNumber_Cysteine = "526"
    public static let NutrientNumber_Glutamine = "528"
    public static let NutrientNumber_Taurine = "529"
    
    public static let NutrientNumber_Water = "255"
    public static let NutrientNumber_Energy_KCal = "208"
    public static let NutrientNumber_Energy_Kj = "268"
    public static let NutrientNumber_Energy_AtwaterGeneralFactors = "957"
    public static let NutrientNumber_Energy_AtwaterSpecificFactors = "958"
    public static let NutrientNumber_Nitrogen = "202"
    public static let NutrientNumber_Protein = "203"
    public static let NutrientNumber_TotalLipid_Fat = "204"
    public static let NutrientNumber_TotalFatNLEA = "298"
    public static let NutrientNumber_Ash = "207"
    public static let NutrientNumber_Alcohol_Ethyl = "221"
    public static let NutrientNumber_SpecificGravity = "227"
    public static let NutrientNumber_AceticAcid = "230"
    public static let NutrientNumber_CitricAcid = "236"
    public static let NutrientNumber_LacticAcid = "242"
    public static let NutrientNumber_MalicAcid = "243"
    
    public static let NutrientNumber_Carbohydrate_ByDifference = "205"
    public static let NutrientNumber_Carbohydrate_BySummation = "205.2"
    public static let NutrientNumber_Carbohydrate_Other = "284"
    public static let NutrientNumber_Fiber_TotalDietary = "291"
    public static let NutrientNumber_Fiber_TotalDietary_AOAC = "293"
    public static let NutrientNumber_Fiber_Soluble = "295"
    public static let NutrientNumber_Fiber_Insoluble = "297"
    public static let NutrientNumber_Sugars_TotalNLEA = "269.3"
    public static let NutrientNumber_Sugars_TotalIncludingNLEA = "269"
    public static let NutrientNumber_Sugars_Added = "539"
    public static let NutrientNumber_Sucrose = "210"
    public static let NutrientNumber_Glucose_Dextrose = "211"
    public static let NutrientNumber_Fructose = "212"
    public static let NutrientNumber_Lactose = "213"
    public static let NutrientNumber_Maltose = "214"
    public static let NutrientNumber_Galactose = "287"
    public static let NutrientNumber_Starch = "209"
    public static let NutrientNumber_Sorbitol = "261"
    public static let NutrientNumber_Xylitol = "290"
    public static let NutrientNumber_Ribose = "294"
    public static let NutrientNumber_TotalSugarAlcohols = "299"
    public static let NutrientNumber_Inositol = "422"
    public static let NutrientNumber_Inulin = "806"
    
    public static let NutrientNumber_Calcium_Ca = "301"
    public static let NutrientNumber_Chlorine_Cl = "302"
    public static let NutrientNumber_Iron_Fe = "303"
    public static let NutrientNumber_Magnesium_Mg = "304"
    public static let NutrientNumber_Phosphorus_P = "305"
    public static let NutrientNumber_Potassium_K = "306"
    public static let NutrientNumber_Sodium_Na = "307"
    public static let NutrientNumber_Sulfur_S = "308"
    public static let NutrientNumber_Zinc_Zn = "309"
    public static let NutrientNumber_Chromium_Cr = "310"
    public static let NutrientNumber_Cobalt_Co = "311"
    public static let NutrientNumber_Copper_Cu = "312"
    public static let NutrientNumber_Fluoride_F = "313"
    public static let NutrientNumber_Iodine_I = "314"
    public static let NutrientNumber_Manganese_Mn = "315"
    public static let NutrientNumber_Molybdenum_Mo = "316"
    public static let NutrientNumber_Selenium_Se = "317"
    public static let NutrientNumber_Boron_B = "354"
    public static let NutrientNumber_Nickel_Ni = "371"
    
    
    public static let NutrientNameOverrides:  [String:String] = [
        NutrientNumber_TotalLipid_Fat: "Total Fat",
        NutrientNumber_FattyAcids_TotalSaturated: "Saturated Fat",
        NutrientNumber_FattyAcids_TotalMonounsaturated: "Monounsaturated Fat",
        NutrientNumber_FattyAcids_TotalPolyunsaturated: "Polyunsaturated Fat",
        NutrientNumber_FattyAcids_TotalTrans: "Trans Fat",
        NutrientNumber_FattyAcids_TotalTrans_Monoenoic: "Trans-Monoenoic",
        NutrientNumber_FattyAcids_TotalTrans_Dienoic: "Trans-Dienoic",
        NutrientNumber_FattyAcids_TotalTrans_PolyEnoic: "Trans-Polyenoic",
        NutrientNumber_VitaminD_D2_Plus_D3_IU: "Vitamin D (D2 + D3), IU",
        NutrientNumber_18_3_N_3_C_C_C_ALA: "ALA (18:3 n-3 c,c,c)",
        NutrientNumber_20_5_N_3_EPA: "EPA (20:5 n-3)",
        NutrientNumber_22_5_N_3_DPA: "DPA (22:5 n-3)",
        NutrientNumber_22_6_N_3_DHA: "DHA (22:6 n-3)",
    ]
    
    public static func makeNutrient(_ nutrient: FdcNutrient, _ amount: Double = 0) -> Nutrient {
        return makeNutrient(nutrient.id, nutrient.nutrientNumber, nutrient.name, amount, nutrient.unitName)
    }
    
    public static func makeNutrient(_ nutrientId: Int, _ fdcNumber: String, _ nutrientName: String, _ amount: Double, _ unitName: String) -> Nutrient {
        var name = nutrientName
        
        let groupNumber = groupNumberForNutrient(fdcNumber)
        let isOther = GroupNumber_Other == groupNumber
        
        if (NutrientNameOverrides.keys.contains(fdcNumber)) {
            name = NutrientNameOverrides[fdcNumber]!
        }
        
        let nutrient = Nutrient(
            fdcId: nutrientId,
            fdcNumber: fdcNumber,
            name: (isOther) ? "\(fdcNumber) \(name)" : name,
            unitName: WeightUnit.unitFrom(unitName, fdcNumber).name,
            amount: amount
        )
        
        if isOther, let analyitcs = swinjectContainer.resolve(NutrientLoggerAnalytics.self) {
            analyitcs.nutrientNotMapped(nutrient)
        }
        
        return nutrient
    }
    
    public static func makeGroupNutrient(_ groupNumber: String) -> NutrientGroup {
        if (GroupNumber_Proximates == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_Proximates,
                name: "Proximates",
                rank: 0
            )
        }
        if (GroupNumber_Carbohydrates == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_Carbohydrates,
                name: "Carbohydrates",
                rank: 1
            )
        }
        if (GroupNumber_Minerals == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_Minerals,
                name: "Minerals",
                rank: 2
            )
        }
        if (GroupNumber_VitaminsAndOtherComponents == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_VitaminsAndOtherComponents,
                name: "Vitamins and Other Components",
                rank: 3
            )
        }
        if (GroupNumber_Lipids == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_Lipids,
                name: "Lipids",
                rank: 4
            )
        }
        if (GroupNumber_AminoAcids == groupNumber) {
            return NutrientGroup(
                fdcNumber: GroupNumber_AminoAcids,
                name: "Amino acids",
                rank: 5
            )
        }
        
        return NutrientGroup(
            fdcNumber: groupNumber,
            name: "Other",
            rank: Int.max
        )
    }
    
    public static func groupNumberForNutrient(_ nutrientNumber: String) -> String {
        if (NutrientNumberToGroupNumberMap.keys.contains(nutrientNumber)) {
            return NutrientNumberToGroupNumberMap[nutrientNumber]!
        }
        
        return GroupNumber_Other
    }
    
    public static func nutrientNumbersInGroup(_ groupNumber: String) -> [String] {
        if (GroupNumberToNutrientNumberMap.keys.contains(groupNumber)) {
            return GroupNumberToNutrientNumberMap[groupNumber]!
        }
        
        return [String]()
    }
    
    public static func isGroupByNumber(_ nutrientNumber: String) -> Bool {
        return GroupNumberToNutrientNumberMap.keys.contains(nutrientNumber)
    }
    
    private static func reverseMap(_ origMap: [String:[String]]) -> [String:String] {
        var reversedMap = [String:String]()
        
        for key in origMap.keys {
            let arr = origMap[key]
            for val in arr! {
                reversedMap[val] = key
            }
        }
        
        return reversedMap
    }
    
    private static var _nutrientNumberToGroupNumberMap: [String:String]?
    private static var NutrientNumberToGroupNumberMap: [String:String] {
        get {
            if (_nutrientNumberToGroupNumberMap == nil) {
                _nutrientNumberToGroupNumberMap = reverseMap(GroupNumberToNutrientNumberMap)
            }
            
            return _nutrientNumberToGroupNumberMap!
        }
    }
    
    private static let GroupNumberToNutrientNumberMap: [String:[String]] = [
        GroupNumber_Carbohydrates: [
            NutrientNumber_Carbohydrate_ByDifference,
            NutrientNumber_Carbohydrate_BySummation,
            NutrientNumber_Carbohydrate_Other,
            NutrientNumber_Fiber_TotalDietary,
            NutrientNumber_Fiber_TotalDietary_AOAC,
            NutrientNumber_Fiber_Soluble,
            NutrientNumber_Fiber_Insoluble,
            NutrientNumber_Sugars_TotalNLEA,
            NutrientNumber_Sugars_TotalIncludingNLEA,
            NutrientNumber_Sugars_Added,
            NutrientNumber_Sucrose,
            NutrientNumber_Glucose_Dextrose,
            NutrientNumber_Fructose,
            NutrientNumber_Lactose,
            NutrientNumber_Maltose,
            NutrientNumber_Galactose,
            NutrientNumber_Starch,
            NutrientNumber_Sorbitol,
            NutrientNumber_Xylitol,
            NutrientNumber_Ribose,
            NutrientNumber_TotalSugarAlcohols,
            NutrientNumber_Inositol,
            NutrientNumber_Inulin,
        ],
        GroupNumber_Minerals: [
            NutrientNumber_Calcium_Ca,
            NutrientNumber_Chlorine_Cl,
            NutrientNumber_Iron_Fe,
            NutrientNumber_Magnesium_Mg,
            NutrientNumber_Phosphorus_P,
            NutrientNumber_Potassium_K,
            NutrientNumber_Sodium_Na,
            NutrientNumber_Sulfur_S,
            NutrientNumber_Zinc_Zn,
            NutrientNumber_Chromium_Cr,
            NutrientNumber_Cobalt_Co,
            NutrientNumber_Copper_Cu,
            NutrientNumber_Fluoride_F,
            NutrientNumber_Iodine_I,
            NutrientNumber_Manganese_Mn,
            NutrientNumber_Molybdenum_Mo,
            NutrientNumber_Selenium_Se,
            NutrientNumber_Boron_B,
            NutrientNumber_Nickel_Ni,
        ],
        GroupNumber_Proximates: [
            NutrientNumber_Water,
            NutrientNumber_Energy_KCal,
            NutrientNumber_Energy_Kj,
            NutrientNumber_Energy_AtwaterGeneralFactors,
            NutrientNumber_Energy_AtwaterSpecificFactors,
            NutrientNumber_Nitrogen,
            NutrientNumber_Protein,
            NutrientNumber_TotalLipid_Fat,
            NutrientNumber_TotalFatNLEA,
            NutrientNumber_Ash,
            NutrientNumber_Alcohol_Ethyl,
            NutrientNumber_SpecificGravity,
            NutrientNumber_AceticAcid,
            NutrientNumber_CitricAcid,
            NutrientNumber_LacticAcid,
            NutrientNumber_MalicAcid,
        ],
        GroupNumber_AminoAcids: [
            NutrientNumber_Tryptophan,
            NutrientNumber_Threonine,
            NutrientNumber_Isoleucine,
            NutrientNumber_Leucine,
            NutrientNumber_Lysine,
            NutrientNumber_Methionine,
            NutrientNumber_Cystine,
            NutrientNumber_Phenylalanine,
            NutrientNumber_Tyrosine,
            NutrientNumber_Valine,
            NutrientNumber_Arginine,
            NutrientNumber_Histidine,
            NutrientNumber_Alanine,
            NutrientNumber_AsparticAcid,
            NutrientNumber_GlutamicAcid,
            NutrientNumber_Glycine,
            NutrientNumber_Proline,
            NutrientNumber_Serine,
            NutrientNumber_Hydroxyproline,
            NutrientNumber_Cysteine,
            NutrientNumber_Glutamine,
            NutrientNumber_Taurine,
        ],
        GroupNumber_VitaminsAndOtherComponents: [
            NutrientNumber_VitaminC_TotalAscorbicAcid,
            NutrientNumber_Thiamin,
            NutrientNumber_Riboflavin,
            NutrientNumber_Niacin,
            NutrientNumber_PantothenicAcid,
            NutrientNumber_VitaminB6,
            NutrientNumber_Choline_Total,
            NutrientNumber_Choline_Free,
            NutrientNumber_Choline_FromPhosphocholine,
            NutrientNumber_Choline_FromPhosphotidylCholine,
            NutrientNumber_Choline_FromGlycerophosphocholine,
            NutrientNumber_Choline_FromSphingomyelin,
            NutrientNumber_Betaine,
            NutrientNumber_FolicAcid,
            NutrientNumber_FormylFolicAcid,
            NutrientNumber_FormylTetrahyrdofolicAcid,
            NutrientNumber_Folate_Food,
            NutrientNumber_MethylTetrahydrofolate,
            NutrientNumber_Folate_DFE,
            NutrientNumber_Folate_Total,
            NutrientNumber_VitaminB12,
            NutrientNumber_VitaminB12_Added,
            NutrientNumber_VitaminA_RAE,
            NutrientNumber_VitaminA_IU,
            NutrientNumber_Retinol,
            NutrientNumber_Carotene_Beta,
            NutrientNumber_Cis_Carotene_Beta,
            NutrientNumber_Trans_Carotene_Beta,
            NutrientNumber_Carotene_Alpha,
            NutrientNumber_Cryptoxanthin_Beta,
            NutrientNumber_Cryptoxanthin_Alpha,
            NutrientNumber_Lycopene,
            NutrientNumber_Cis_Lycopene,
            NutrientNumber_Trans_Lycopene,
            NutrientNumber_Lutein_Zeaxanthin,
            NutrientNumber_Lutein,
            NutrientNumber_Zeaxanthin,
            NutrientNumber_Cis_Lutein_Zeaxanthin,
            NutrientNumber_VitaminD_D2_Plus_D3_IU,
            NutrientNumber_VitaminD_D2,
            NutrientNumber_VitaminD3_Cholecalciferol,
            NutrientNumber_Hydroxycholecalciferol,
            NutrientNumber_VitaminD_D2_Plus_D3,
            NutrientNumber_VitaminK_Menaquinone_4,
            NutrientNumber_VitaminK_Dihydrophylloquinone,
            NutrientNumber_VitaminK_Phylloquinone,
            NutrientNumber_VitaminE_Alpha_Tocopherol,
            NutrientNumber_VitaminE_LabelEntryPrimarily,
            NutrientNumber_VitaminE,
            NutrientNumber_VitaminE_Added,
            NutrientNumber_Tocopherol_Beta,
            NutrientNumber_Tocopherol_Gamma,
            NutrientNumber_Tocopherol_Delta,
            NutrientNumber_Tocotrienol_Alpha,
            NutrientNumber_Tocotrienol_Beta,
            NutrientNumber_Tocotrienol_Gamma,
            NutrientNumber_Tocotrienol_Delta,
            NutrientNumber_Caffeine,
            NutrientNumber_Theobromine,
            NutrientNumber_Biotin,
            NutrientNumber_Phytoene,
            NutrientNumber_Phytofluene,
            NutrientNumber_Epigallocatechin3Gallate,
        ],
        GroupNumber_Lipids: [
            NutrientNumber_FattyAcids_TotalSaturated,
            NutrientNumber_4_0,
            NutrientNumber_5_0,
            NutrientNumber_6_0,
            NutrientNumber_7_0,
            NutrientNumber_8_0,
            NutrientNumber_9_0,
            NutrientNumber_10_0,
            NutrientNumber_11_0,
            NutrientNumber_12_0,
            NutrientNumber_13_0,
            NutrientNumber_14_0,
            NutrientNumber_15_0,
            NutrientNumber_16_0,
            NutrientNumber_17_0,
            NutrientNumber_18_0,
            NutrientNumber_20_0,
            NutrientNumber_21_0,
            NutrientNumber_22_0,
            NutrientNumber_23_0,
            NutrientNumber_24_0,
            NutrientNumber_FattyAcids_TotalMonounsaturated,
            NutrientNumber_12_1,
            NutrientNumber_14_1,
            NutrientNumber_14_1_T,
            NutrientNumber_14_1_C,
            NutrientNumber_15_1,
            NutrientNumber_16_1,
            NutrientNumber_16_1_C,
            NutrientNumber_17_1,
            NutrientNumber_17_1_C,
            NutrientNumber_18_1,
            NutrientNumber_18_1_C,
            NutrientNumber_18_1_11_t_18_1t_n_7,
            NutrientNumber_20_1,
            NutrientNumber_20_1_C,
            NutrientNumber_20_1_T,
            NutrientNumber_22_1,
            NutrientNumber_22_1_C,
            NutrientNumber_22_1_N_9,
            NutrientNumber_22_1_N_11,
            NutrientNumber_24_1_C,
            NutrientNumber_FattyAcids_TotalPolyunsaturated,
            NutrientNumber_18_2,
            NutrientNumber_18_2_I,
            NutrientNumber_18_2_C,
            NutrientNumber_18_2_N_6_C_C,
            NutrientNumber_18_2_CLAs,
            NutrientNumber_18_3,
            NutrientNumber_18_3_C,
            NutrientNumber_18_3_T,
            NutrientNumber_18_3_I,
            NutrientNumber_18_3_N_3_C_C_C_ALA,
            NutrientNumber_18_3_N_6_C_C_C,
            NutrientNumber_18_4,
            NutrientNumber_20_2_C,
            NutrientNumber_20_2_N_6_C_C,
            NutrientNumber_20_3,
            NutrientNumber_20_3_C,
            NutrientNumber_20_3_N_3,
            NutrientNumber_20_3_N_6,
            NutrientNumber_20_3_N_9,
            NutrientNumber_20_4,
            NutrientNumber_20_4_C,
            NutrientNumber_20_4_N_6,
            NutrientNumber_20_5_C,
            NutrientNumber_20_5_N_3_EPA,
            NutrientNumber_21_5,
            NutrientNumber_22_2,
            NutrientNumber_22_3,
            NutrientNumber_22_4,
            NutrientNumber_22_5_C,
            NutrientNumber_22_5_N_3_DPA,
            NutrientNumber_22_6_C,
            NutrientNumber_22_6_N_3_DHA,
            NutrientNumber_FattyAcids_TotalTrans,
            NutrientNumber_FattyAcids_TotalTrans_Monoenoic,
            NutrientNumber_FattyAcids_TotalTrans_PolyEnoic,
            NutrientNumber_16_1_T,
            NutrientNumber_18_1_T,
            NutrientNumber_22_1_T,
            NutrientNumber_FattyAcids_TotalTrans_Dienoic,
            NutrientNumber_18_2_T_NotFurtherDefined,
            NutrientNumber_18_2_T_T,
            NutrientNumber_Cholesterol,
            NutrientNumber_Phytosterols,
            NutrientNumber_PhytosterolsOther,
            NutrientNumber_Stigmasterol,
            NutrientNumber_Campesterol,
            NutrientNumber_Brassicasterol,
            NutrientNumber_Beta_Sitosterol,
            NutrientNumber_Campestanol,
            NutrientNumber_Beta_Sitostanol,
            NutrientNumber_Delta5Avenasterol,
        ]
    ]
}
