//
//  NutrientRdis.swift
//  NutrientRdis
//
//  Created by Jason Vance on 8/14/21.
//

import Foundation

protocol NutrientRdis {
    var nutrientFdcNumber: String { get }
    func getRdi(_ user: User) -> LifeStageNutrientRdi?
    func getRdi(_ gender: Gender, _ age: TimeInterval) -> LifeStageNutrientRdi?
    func addLifeStageRdi(_ rdi: LifeStageNutrientRdi)
}

class AbstractNutrientRdis: NutrientRdis {
    private var lifeStageRdis: [LifeStageNutrientRdi] = [LifeStageNutrientRdi]()
    
    public let nutrientFdcNumber: String
    
    public init(_ nutrientFdcNumber: String) {
        self.nutrientFdcNumber = nutrientFdcNumber
    }

    public func getRdi(_ user: User) -> LifeStageNutrientRdi? {
        let userGender = user.gender
        let userAge = user.getUserAge()

        return getRdi(userGender, userAge)
    }

    public func getRdi(_ gender: Gender, _ age: TimeInterval) -> LifeStageNutrientRdi? {
        for rdi in lifeStageRdis {
            if (rdi.matches(gender, age)) {
                return rdi
            }
        }
        return nil
    }

    public func addLifeStageRdi(_ rdi: LifeStageNutrientRdi) {
        lifeStageRdis.append(rdi)
    }
}
