//
//  NutrientRdiLibrary.swift
//  NutrientRdiLibrary
//
//  Created by Jason Vance on 8/15/21.
//

import Foundation

protocol NutrientRdiLibrary {
    func getRdis(_ nutrientNumber: String) -> NutrientRdis?
}

class UsdaNutrientRdiLibrary: NutrientRdiLibrary {
    let rdis: [String:NutrientRdis]
    
    public static func create() -> UsdaNutrientRdiLibrary {
        var rdis = [NutrientRdis]()
        
        rdis.append(Biotin_RDIs())
        rdis.append(Boron_RDIs())
        rdis.append(Calcium_RDIs())
        rdis.append(Choline_RDIs())
        rdis.append(Chromium_RDIs())
        rdis.append(Copper_RDIs())
        rdis.append(Fluoride_RDIs())
        rdis.append(Folate_RDIs())
        rdis.append(Iodine_RDIs())
        rdis.append(Iron_RDIs())
        rdis.append(Magnesium_RDIs())
        rdis.append(Manganese_RDIs())
        rdis.append(Molybdenum_RDIs())
        rdis.append(Niacin_RDIs())
        rdis.append(Omega3ALA_RDIs())
        rdis.append(PantothenicAcid_RDIs())
        rdis.append(Phosphorus_RDIs())
        rdis.append(Potassium_RDIs())
        rdis.append(Riboflavin_RDIs())
        rdis.append(Selenium_RDIs())
        rdis.append(Sodium_RDIs())
        rdis.append(Thiamin_RDIs())
        rdis.append(VitaminA_RDIs())
        rdis.append(VitaminB6_RDIs())
        rdis.append(VitaminB12_RDIs())
        rdis.append(VitaminC_RDIs())
        rdis.append(VitaminD_RDIs())
        rdis.append(VitaminE_RDIs())
        rdis.append(VitaminK_RDIs())
        rdis.append(Zinc_RDIs())
        rdis.append(Water_RDIs())

        if (rdis.count != 31) {
            fatalError("The RDIs are not all here")
        }
        
        return UsdaNutrientRdiLibrary(rdis)
    }
    
    private init(_ rdis: [NutrientRdis]) {
        var tmp = [String:NutrientRdis]()
        for rdi in rdis {
            tmp[rdi.nutrientFdcNumber] = rdi
        }
        self.rdis = tmp
    }
    
    public func getRdis(_ nutrientNumber: String) -> NutrientRdis? {
        if (rdis.keys.contains(nutrientNumber)) {
            return rdis[nutrientNumber]
        }
        return nil
    }
}
