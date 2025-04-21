//
//  NutritionFactsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/18/25.
//

import SwiftUI

struct NutritionFactsSection: View {
    
    enum UIConsts {
        public static let lineWidth_Thin: CGFloat = 1
        public static let lineWidth_Regular: CGFloat = 2
        public static let lineWidth_Thick: CGFloat = 6
        public static let lineWidth_ExtraThick: CGFloat = 14
        public static let margin: CGFloat = 8

        public static let fontSize_Name: CGFloat = 48
        public static let fontSize_Calories: CGFloat = 38
        public static let fontSize_Portion: CGFloat = 28
        public static let fontSize_Nutrient: CGFloat = 18

        public static var outlineMargin: CGFloat { margin }
        public static var outlineWidth: CGFloat { lineWidth_Regular }
        public static var thinLineWidth: CGFloat { lineWidth_Thin }

        public static var textMargin: CGFloat { 2 * margin + outlineWidth }
        public static var nameFontSize: CGFloat { fontSize_Name }
        public static var portionFontSize: CGFloat { fontSize_Portion }
        public static var caloriesFontSize: CGFloat { fontSize_Calories }
        public static var nutrientFontSize: CGFloat { fontSize_Nutrient }
    }
    
    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary
    
    let nutrients: [String:Nutrient]
    let portionGrams: String
    let portionValue: String
    
    private var otherNutrients: [Nutrient] {
        Set(nutrients.map(\.key))
            .subtracting(Self.specificNutrientNumbers)
            .compactMap { nutrients[$0] }
            .sorted { $0.fdcNumber < $1.fdcNumber }
    }
    
    private var user: User { userService.currentUser }
    
    init(
        nutrients: [Nutrient],
        portionGrams: String,
        portionValue: String
    ) {
        self.nutrients = nutrients.reduce(into: [:]) { $0[$1.fdcNumber] = $1 }
        self.portionGrams = portionGrams
        self.portionValue = portionValue
    }
    
    var body: some View {
        Section(header: Text("Nutrition Facts")) {
            NutritionFactsCap(isTop: true)
            
            NutritionFactsPortion()
            NutritionFactsLine(UIConsts.lineWidth_ExtraThick)
            
            Calories()
            Energy()
            WaterEtc()
            Alcohol()
            Ash()
            FattyNutrients()
            Sodium()
            Carbohydrates()
            Protein()
            NutritionFactsLine(UIConsts.lineWidth_ExtraThick)
            
            VitaminA()
            VitaminB()
            VitaminC()
            VitaminD()
            VitaminE()
            VitaminK()
            Minerals()
            Folate()
            Choline()
            OtherVitamins()
            
            OtherVarious()
            Phytosterols()
            OtherAcids()
            AminoAcids()
            FattyAcids()
            
            OtherNutrients()
            
            NutritionFactsCap(isTop: false)
        }
    }
    
    @ViewBuilder private func NutritionFactsCap(isTop: Bool) -> some View {
        Rectangle()
            .frame(height: 2)
            .padding(.top, (isTop) ? UIConsts.outlineMargin : 0)
            .padding(.bottom, (isTop) ? 0 : UIConsts.outlineMargin)
            .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsLine(_ width: CGFloat) -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            Spacer()
            Rectangle()
                .frame(height: width)
                .padding(.vertical, 2)
            Spacer()
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func NutritionFactsPortion() -> some View {
        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            VStack {
                HStack {
                    Text("Portion size")
                        .font(.system(size: UIConsts.portionFontSize).bold())
                    Spacer()
                    Text(portionGrams)
                        .font(.system(size: UIConsts.portionFontSize).bold())
                }
                HStack {
                    Spacer()
                    Text(portionValue)
                        .font(.system(size: UIConsts.portionFontSize).bold())
                }
            }
            .padding(.leading, 0.1)
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
    }
    
    @ViewBuilder private func Calories() -> some View {
        if let calories = nutrients[FdcNutrientGroupMapper.NutrientNumber_Energy_KCal] {
            HStack {
                Rectangle()
                    .frame(width: UIConsts.outlineWidth)
                VStack {
                    HStack {
                        Text("Amount per portion")
                            .font(.system(size: UIConsts.nutrientFontSize).bold())
                        Spacer()
                    }
                    HStack {
                        Text("Calories")
                            .font(.system(size: UIConsts.caloriesFontSize).bold())
                        Spacer()
                        Text(calories.amount.formatted(maxDigits: 1))
                            .font(.system(size: UIConsts.caloriesFontSize).bold())
                    }
                }
                .padding(.horizontal, 0.1)
                Rectangle()
                    .frame(width: UIConsts.outlineWidth)
            }
            .nutritionFactsRow()
            
            NutritionFactsLine(UIConsts.lineWidth_Thick)
        }
    }
    
    @ViewBuilder private func Energy() -> some View {
        if let energyKj = nutrients[FdcNutrientGroupMapper.NutrientNumber_Energy_Kj] {
            NutrientRow(energyKj, isNameBold: true)
        }
        if let energyGeneralFactors = nutrients[FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterGeneralFactors] {
            NutrientRow(energyGeneralFactors, isNameBold: true)
        }
        if let energySpecificFactors = nutrients[FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterSpecificFactors] {
            NutrientRow(energySpecificFactors, isNameBold: true)
        }
    }
    
    @ViewBuilder private func WaterEtc() -> some View {
        if let water = nutrients[FdcNutrientGroupMapper.NutrientNumber_Water] {
            NutrientRow(water, isNameBold: true)
        }
        if let nitrogen = nutrients[FdcNutrientGroupMapper.NutrientNumber_Nitrogen] {
            NutrientRow(nitrogen, isNameBold: true)
        }
        if let specificGravity = nutrients[FdcNutrientGroupMapper.NutrientNumber_SpecificGravity] {
            NutrientRow(specificGravity, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Alcohol() -> some View {
        if let alcohol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Alcohol_Ethyl] {
            NutrientRow(alcohol, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Ash() -> some View {
        if let ash = nutrients[FdcNutrientGroupMapper.NutrientNumber_Ash] {
            NutrientRow(ash, isNameBold: true)
        }
    }
    
    @ViewBuilder private func FattyNutrients() -> some View {
        if let totalFatNlea = nutrients[FdcNutrientGroupMapper.NutrientNumber_TotalFatNLEA] {
            NutrientRow(totalFatNlea, isNameBold: true)
        }
        if let totalFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat] {
            NutrientRow(totalFat, isNameBold: true)
        }
        if let saturatedFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalSaturated] {
            NutrientRow(saturatedFat, indentLevel: 1)
        }
        if let monounsaturatedFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalMonounsaturated] {
            NutrientRow(monounsaturatedFat, indentLevel: 1)
        }
        if let polyunsaturatedFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalPolyunsaturated] {
            NutrientRow(polyunsaturatedFat, indentLevel: 1)
        }
        if let transFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans] {
            NutrientRow(transFat, indentLevel: 1)
        }
        if let transMonoFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Monoenoic] {
            NutrientRow(transMonoFat, indentLevel: 2)
        }
        if let transDiFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Dienoic] {
            NutrientRow(transDiFat, indentLevel: 2)
        }
        if let transPolyFat = nutrients[FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_PolyEnoic] {
            NutrientRow(transPolyFat, indentLevel: 2)
        }
        if let cholesterol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Cholesterol] {
            NutrientRow(cholesterol, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Sodium() -> some View {
        if let sodium = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sodium_Na] {
            NutrientRow(sodium, isNameBold: true)
        }
    }
    
    @ViewBuilder private func Carbohydrates() -> some View {
        if let carbohydrateOther = nutrients[FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_Other] {
            NutrientRow(carbohydrateOther, isNameBold: true)
        }
        if let carbohydrateDiff = nutrients[FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference] {
            NutrientRow(carbohydrateDiff, isNameBold: true)
        }
        if let carbohydrateSum = nutrients[FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_BySummation] {
            NutrientRow(carbohydrateSum, isNameBold: true)
        }
        if let starch = nutrients[FdcNutrientGroupMapper.NutrientNumber_Starch] {
            NutrientRow(starch, indentLevel: 1)
        }
        if let dietaryFiberAoac = nutrients[FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary_AOAC] {
            NutrientRow(dietaryFiberAoac, indentLevel: 1)
        }
        if let dietaryFiber = nutrients[FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary] {
            NutrientRow(dietaryFiber, indentLevel: 1)
        }
        if let solubleFiber = nutrients[FdcNutrientGroupMapper.NutrientNumber_Fiber_Soluble] {
            NutrientRow(solubleFiber, indentLevel: 2)
        }
        if let insolubleFiber = nutrients[FdcNutrientGroupMapper.NutrientNumber_Fiber_Insoluble] {
            NutrientRow(insolubleFiber, indentLevel: 2)
        }
        if let inulin = nutrients[FdcNutrientGroupMapper.NutrientNumber_Inulin] {
            NutrientRow(inulin, indentLevel: 2)
        }
        if let sugars = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalIncludingNLEA] {
            NutrientRow(sugars, indentLevel: 1)
        }
        if let sugarsAdded = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sugars_Added] {
            NutrientRow(sugarsAdded, indentLevel: 2)
        }
        if let nleaSugars = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalNLEA] {
            NutrientRow(nleaSugars, indentLevel: 2)
        }
        if let sucrose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sucrose] {
            NutrientRow(sucrose, indentLevel: 2)
        }
        if let glucose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Glucose_Dextrose] {
            NutrientRow(glucose, indentLevel: 2)
        }
        if let fructose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Fructose] {
            NutrientRow(fructose, indentLevel: 2)
        }
        if let lactose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Lactose] {
            NutrientRow(lactose, indentLevel: 2)
        }
        if let maltose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Maltose] {
            NutrientRow(maltose, indentLevel: 2)
        }
        if let galactose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Galactose] {
            NutrientRow(galactose, indentLevel: 2)
        }
        if let ribose = nutrients[FdcNutrientGroupMapper.NutrientNumber_Ribose] {
            NutrientRow(ribose, indentLevel: 2)
        }
        if let totalSugarAlcohols = nutrients[FdcNutrientGroupMapper.NutrientNumber_TotalSugarAlcohols] {
            NutrientRow(totalSugarAlcohols, indentLevel: 1)
        }
        if let sorbitol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Sorbitol] {
            NutrientRow(sorbitol, indentLevel: 2)
        }
        if let xylitol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Xylitol] {
            NutrientRow(xylitol, indentLevel: 2)
        }
        if let inositol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Inositol] {
            NutrientRow(inositol, indentLevel: 1)
        }
    }
    
    @ViewBuilder private func Protein() -> some View {
        if let protein = nutrients[FdcNutrientGroupMapper.NutrientNumber_Protein] {
            NutrientRow(protein, isNameBold: true, showDivider: false)
        }
    }
    
    @ViewBuilder private func VitaminA() -> some View {
        if let vitaminAIU = nutrients[FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU] {
            NutrientRow(vitaminAIU)
        }
        if let vitaminARae = nutrients[FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE] {
            NutrientRow(vitaminARae)
        }
        if let retinol = nutrients[FdcNutrientGroupMapper.NutrientNumber_Retinol] {
            NutrientRow(retinol, indentLevel: 1)
        }
        if let betaCarotene = nutrients[FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta] {
            NutrientRow(betaCarotene, indentLevel: 1)
        }
        if let cisBetaCarotene = nutrients[FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta] {
            NutrientRow(cisBetaCarotene, indentLevel: 1)
        }
        if let transBetaCarotene = nutrients[FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta] {
            NutrientRow(transBetaCarotene, indentLevel: 1)
        }
        if let alphaCarotene = nutrients[FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha] {
            NutrientRow(alphaCarotene, indentLevel: 1)
        }
        if let cryptoxanthinAlpha = nutrients[FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Alpha] {
            NutrientRow(cryptoxanthinAlpha, indentLevel: 1)
        }
        if let cryptoxanthinBeta = nutrients[FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Beta] {
            NutrientRow(cryptoxanthinBeta, indentLevel: 1)
        }
    }
    
    @ViewBuilder private func VitaminB() -> some View {
        ForEach(Self.vitaminBNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func VitaminC() -> some View {
        ForEach(Self.vitaminCNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func VitaminD() -> some View {
        ForEach(Self.vitaminDNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func VitaminE() -> some View {
        ForEach(Self.vitaminENumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func VitaminK() -> some View {
        ForEach(Self.vitaminKNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func Minerals() -> some View {
        ForEach(Self.mineralNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func Folate() -> some View {
        ForEach(Self.folateNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func Choline() -> some View {
        ForEach(Self.cholineNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func OtherVitamins() -> some View {
        ForEach(Self.otherVitaminNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func OtherVarious() -> some View {
        ForEach(Self.otherVariousNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func Phytosterols() -> some View {
        ForEach(Self.phytosterolNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func OtherAcids() -> some View {
        ForEach(Self.otherAcidNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func AminoAcids() -> some View {
        ForEach(Self.aminoAcidNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func FattyAcids() -> some View {
        ForEach(Self.fattyAcidNumbers, id: \.self) { number in
            if let nutrient = nutrients[number] {
                NutrientRow(nutrient)
            }
        }
    }
    
    @ViewBuilder private func OtherNutrients() -> some View {
        let otherNutrients = otherNutrients
        let last = otherNutrients.last
        
        ForEach(otherNutrients) { nutrient in
            NutrientRow(nutrient, showDivider: nutrient.fdcNumber != last?.fdcNumber)
        }
    }
    
    @ViewBuilder private func NutrientRow(
        _ nutrient: Nutrient,
        indentLevel: Int = 0,
        isNameBold: Bool = false,
        showDivider: Bool = true
    ) -> some View {
        let rdi = rdiLibrary.getRdis(nutrient.fdcNumber)?.getRdi(user)
        let number = nutrient.amount.formatted(maxDigits: 3)

        HStack {
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
            HStack {
                Text(nutrient.name)
                    .font(.system(size: UIConsts.nutrientFontSize))
                    .bold(isNameBold)
                Text("\(number)\(nutrient.unitName.lowercased())")
                    .font(.system(size: UIConsts.nutrientFontSize))
                Spacer()

                if let rdi = rdi, rdi.recommendedAmount > 0 {
                    let nutrientUnit = WeightUnit.unitFrom(nutrient)
                    let recommendedAmount = rdi.unit.convertTo(nutrientUnit, rdi.recommendedAmount)
                    let percent = (nutrient.amount / recommendedAmount) * 100.0
                    
                    Text("\(Int(percent))%")
                        .font(.system(size: UIConsts.nutrientFontSize))
                        .bold()
                }
           }
            .padding(.horizontal, 0.1)
            .padding(.leading, CGFloat(indentLevel) * 16)
            Rectangle()
                .frame(width: UIConsts.outlineWidth)
        }
        .nutritionFactsRow()
        
        if showDivider {
            NutritionFactsLine(UIConsts.lineWidth_Thin)
        }
    }
}

fileprivate extension View {
    func nutritionFactsRow() -> some View {
        self
            .padding(.leading, NutritionFactsSection.UIConsts.outlineMargin)
            .padding(.trailing, NutritionFactsSection.UIConsts.outlineMargin)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

fileprivate extension NutritionFactsSection {
    
    static let specificNutrientNumbers: Set<String> = {
        miscSpecificNutrientNumbers
            .union(vitaminBNumbers)
            .union(vitaminCNumbers)
            .union(vitaminDNumbers)
            .union(vitaminENumbers)
            .union(vitaminKNumbers)
            .union(mineralNumbers)
            .union(folateNumbers)
            .union(cholineNumbers)
            .union(otherVitaminNumbers)
            .union(otherVariousNumbers)
            .union(phytosterolNumbers)
            .union(otherAcidNumbers)
            .union(aminoAcidNumbers)
            .union(fattyAcidNumbers)
    }()

    
    static let miscSpecificNutrientNumbers: Set<String> = [
        FdcNutrientGroupMapper.NutrientNumber_Energy_KCal,
        FdcNutrientGroupMapper.NutrientNumber_Energy_Kj,
        FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterGeneralFactors,
        FdcNutrientGroupMapper.NutrientNumber_Energy_AtwaterSpecificFactors,
        
        FdcNutrientGroupMapper.NutrientNumber_Water,
        FdcNutrientGroupMapper.NutrientNumber_Nitrogen,
        FdcNutrientGroupMapper.NutrientNumber_SpecificGravity,
        FdcNutrientGroupMapper.NutrientNumber_Alcohol_Ethyl,
        
        FdcNutrientGroupMapper.NutrientNumber_Ash,
        
        FdcNutrientGroupMapper.NutrientNumber_TotalFatNLEA,
        FdcNutrientGroupMapper.NutrientNumber_TotalLipid_Fat,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalSaturated,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalMonounsaturated,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalPolyunsaturated,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Monoenoic,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_Dienoic,
        FdcNutrientGroupMapper.NutrientNumber_FattyAcids_TotalTrans_PolyEnoic,
        FdcNutrientGroupMapper.NutrientNumber_Cholesterol,
        
        FdcNutrientGroupMapper.NutrientNumber_Sodium_Na,
        
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_Other,
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_ByDifference,
        FdcNutrientGroupMapper.NutrientNumber_Carbohydrate_BySummation,
        FdcNutrientGroupMapper.NutrientNumber_Starch,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary_AOAC,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_TotalDietary,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_Soluble,
        FdcNutrientGroupMapper.NutrientNumber_Fiber_Insoluble,
        FdcNutrientGroupMapper.NutrientNumber_Inulin,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalIncludingNLEA,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_Added,
        FdcNutrientGroupMapper.NutrientNumber_Sugars_TotalNLEA,
        FdcNutrientGroupMapper.NutrientNumber_Sucrose,
        FdcNutrientGroupMapper.NutrientNumber_Glucose_Dextrose,
        FdcNutrientGroupMapper.NutrientNumber_Fructose,
        FdcNutrientGroupMapper.NutrientNumber_Lactose,
        FdcNutrientGroupMapper.NutrientNumber_Maltose,
        FdcNutrientGroupMapper.NutrientNumber_Galactose,
        FdcNutrientGroupMapper.NutrientNumber_Ribose,
        FdcNutrientGroupMapper.NutrientNumber_TotalSugarAlcohols,
        FdcNutrientGroupMapper.NutrientNumber_Sorbitol,
        FdcNutrientGroupMapper.NutrientNumber_Xylitol,
        FdcNutrientGroupMapper.NutrientNumber_Inositol,
        
        FdcNutrientGroupMapper.NutrientNumber_Protein,
        
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU,
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
        FdcNutrientGroupMapper.NutrientNumber_Retinol,
        FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Beta,
    ]
        
    static let vitaminBNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Thiamin,
        FdcNutrientGroupMapper.NutrientNumber_Riboflavin,
        FdcNutrientGroupMapper.NutrientNumber_Niacin,
        FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB6,
        FdcNutrientGroupMapper.NutrientNumber_Biotin,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12_Added,
    ]
        
    static let vitaminCNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
    ]
        
    static let vitaminDNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD3_Cholecalciferol,
        FdcNutrientGroupMapper.NutrientNumber_Hydroxycholecalciferol,
    ]
        
    static let vitaminENumbers = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Added,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_LabelEntryPrimarily,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Delta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Delta,
    ]
        
    static let vitaminKNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Menaquinone_4,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Dihydrophylloquinone,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone,
    ]
        
    static let mineralNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
        FdcNutrientGroupMapper.NutrientNumber_Chlorine_Cl,
        FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
        FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
        FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P,
        FdcNutrientGroupMapper.NutrientNumber_Potassium_K,
        FdcNutrientGroupMapper.NutrientNumber_Sulfur_S,
        FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
        FdcNutrientGroupMapper.NutrientNumber_Chromium_Cr,
        FdcNutrientGroupMapper.NutrientNumber_Cobalt_Co,
        FdcNutrientGroupMapper.NutrientNumber_Copper_Cu,
        FdcNutrientGroupMapper.NutrientNumber_Fluoride_F,
        FdcNutrientGroupMapper.NutrientNumber_Iodine_I,
        FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn,
        FdcNutrientGroupMapper.NutrientNumber_Molybdenum_Mo,
        FdcNutrientGroupMapper.NutrientNumber_Selenium_Se,
        FdcNutrientGroupMapper.NutrientNumber_Boron_B,
        FdcNutrientGroupMapper.NutrientNumber_Nickel_Ni,
    ]
        
    static let folateNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Total,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Food,
        FdcNutrientGroupMapper.NutrientNumber_MethylTetrahydrofolate,
        FdcNutrientGroupMapper.NutrientNumber_FolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylFolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylTetrahyrdofolicAcid,
    ]
        
    static let cholineNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Choline_Total,
        FdcNutrientGroupMapper.NutrientNumber_Choline_Free,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromGlycerophosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphotidylCholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromSphingomyelin,
    ]
        
    static let otherVitaminNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Lutein_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Lutein,
        FdcNutrientGroupMapper.NutrientNumber_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lutein_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Betaine,
    ]
        
    static let otherVariousNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Caffeine,
        FdcNutrientGroupMapper.NutrientNumber_Theobromine,
        FdcNutrientGroupMapper.NutrientNumber_Epigallocatechin3Gallate,
        FdcNutrientGroupMapper.NutrientNumber_Phytoene,
        FdcNutrientGroupMapper.NutrientNumber_Phytofluene,
    ]
        
    static let phytosterolNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Phytosterols,
        FdcNutrientGroupMapper.NutrientNumber_PhytosterolsOther,
        FdcNutrientGroupMapper.NutrientNumber_Stigmasterol,
        FdcNutrientGroupMapper.NutrientNumber_Campesterol,
        FdcNutrientGroupMapper.NutrientNumber_Brassicasterol,
        FdcNutrientGroupMapper.NutrientNumber_Beta_Sitosterol,
        FdcNutrientGroupMapper.NutrientNumber_Campestanol,
        FdcNutrientGroupMapper.NutrientNumber_Beta_Sitostanol,
        FdcNutrientGroupMapper.NutrientNumber_Delta5Avenasterol,
    ]
        
    static let otherAcidNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_AceticAcid,
        FdcNutrientGroupMapper.NutrientNumber_CitricAcid,
        FdcNutrientGroupMapper.NutrientNumber_LacticAcid,
        FdcNutrientGroupMapper.NutrientNumber_MalicAcid,
    ]
        
    static let aminoAcidNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_Tryptophan,
        FdcNutrientGroupMapper.NutrientNumber_Threonine,
        FdcNutrientGroupMapper.NutrientNumber_Isoleucine,
        FdcNutrientGroupMapper.NutrientNumber_Leucine,
        FdcNutrientGroupMapper.NutrientNumber_Lysine,
        FdcNutrientGroupMapper.NutrientNumber_Methionine,
        FdcNutrientGroupMapper.NutrientNumber_Cystine,
        FdcNutrientGroupMapper.NutrientNumber_Phenylalanine,
        FdcNutrientGroupMapper.NutrientNumber_Tyrosine,
        FdcNutrientGroupMapper.NutrientNumber_Valine,
        FdcNutrientGroupMapper.NutrientNumber_Arginine,
        FdcNutrientGroupMapper.NutrientNumber_Histidine,
        FdcNutrientGroupMapper.NutrientNumber_Alanine,
        FdcNutrientGroupMapper.NutrientNumber_AsparticAcid,
        FdcNutrientGroupMapper.NutrientNumber_GlutamicAcid,
        FdcNutrientGroupMapper.NutrientNumber_Glycine,
        FdcNutrientGroupMapper.NutrientNumber_Proline,
        FdcNutrientGroupMapper.NutrientNumber_Serine,
        FdcNutrientGroupMapper.NutrientNumber_Hydroxyproline,
        FdcNutrientGroupMapper.NutrientNumber_Cysteine,
        FdcNutrientGroupMapper.NutrientNumber_Glutamine,
        FdcNutrientGroupMapper.NutrientNumber_Taurine
    ]
        
    static let fattyAcidNumbers = [
        FdcNutrientGroupMapper.NutrientNumber_18_3_N_3_C_C_C_ALA,
        FdcNutrientGroupMapper.NutrientNumber_20_5_N_3_EPA,
        FdcNutrientGroupMapper.NutrientNumber_22_5_N_3_DPA,
        FdcNutrientGroupMapper.NutrientNumber_22_6_N_3_DHA
    ]
}

#Preview {
    let nutrients = FoodItem.sampleFoods.first!.nutrientGroups
        .flatMap { group in
            group.nutrients.compactMap { nutrient in
                (nutrient.amount > 0) ? nutrient : nil
            }
        }
    
    List {
        NutritionFactsSection(
            nutrients: nutrients,
            portionGrams: "100g",
            portionValue: "1 Cup"
        )
    }
    .listDefaultModifiers()
}
