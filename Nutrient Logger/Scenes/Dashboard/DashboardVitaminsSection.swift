//
//  DashboardVitaminsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

//TODO: Navigate to VitaminDetailView with all of the nutrients and foods containing those nutrients
//  IE. Vitamin A screen has all Vitamin A's, Retinol, beta carotene, etc
struct DashboardVitaminsSection: View {
    
    static let blacklist: Set<String> = [
        FdcNutrientGroupMapper.NutrientNumber_Choline_Free,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromPhosphotidylCholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromGlycerophosphocholine,
        FdcNutrientGroupMapper.NutrientNumber_Choline_FromSphingomyelin,
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_IU,
        FdcNutrientGroupMapper.NutrientNumber_Retinol,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Cryptoxanthin_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Trans_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Lutein,
        FdcNutrientGroupMapper.NutrientNumber_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Cis_Lutein_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Added,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_LabelEntryPrimarily,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocopherol_Delta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Gamma,
        FdcNutrientGroupMapper.NutrientNumber_Tocotrienol_Delta,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Menaquinone_4,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Dihydrophylloquinone,
        FdcNutrientGroupMapper.NutrientNumber_FolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylFolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_FormylTetrahyrdofolicAcid,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Total,
        FdcNutrientGroupMapper.NutrientNumber_Folate_Food,
        FdcNutrientGroupMapper.NutrientNumber_MethylTetrahydrofolate,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3_IU,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD3_Cholecalciferol,
        FdcNutrientGroupMapper.NutrientNumber_Hydroxycholecalciferol,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12_Added
    ]
    
    static let orderedWhitelist: [String] = [
        FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE,
        FdcNutrientGroupMapper.NutrientNumber_Thiamin,
        FdcNutrientGroupMapper.NutrientNumber_Riboflavin,
        FdcNutrientGroupMapper.NutrientNumber_Niacin,
        FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB6,
        FdcNutrientGroupMapper.NutrientNumber_Folate_DFE,
        FdcNutrientGroupMapper.NutrientNumber_VitaminB12,
        FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid,
        FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3,
        FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol,
        FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone,
        FdcNutrientGroupMapper.NutrientNumber_Choline_Total,
        FdcNutrientGroupMapper.NutrientNumber_Betaine,
        FdcNutrientGroupMapper.NutrientNumber_Carotene_Alpha,
        FdcNutrientGroupMapper.NutrientNumber_Carotene_Beta,
        FdcNutrientGroupMapper.NutrientNumber_Caffeine,
        FdcNutrientGroupMapper.NutrientNumber_Lycopene,
        FdcNutrientGroupMapper.NutrientNumber_Lutein_Zeaxanthin,
        FdcNutrientGroupMapper.NutrientNumber_Theobromine,
//        FdcNutrientGroupMapper.NutrientNumber_Biotin, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Phytoene, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Phytofluene, // Nothing in the database has this in it
//        FdcNutrientGroupMapper.NutrientNumber_Epigallocatechin3Gallate // Nothing in the database has this in it
    ]
    
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService

    let vitaminsKey = FdcNutrientGroupMapper.GroupNumber_VitaminsAndOtherComponents
    
    let aggregator: NutrientDataAggregator
    
    private var otherNutrientIds: [String] {
        guard let group = aggregator.nutrientGroups
            .first(where: { $0.fdcNumber == vitaminsKey })
        else {
            return []
        }
        
        return Set(group.nutrients.map(\.fdcNumber))
            .filter { !Self.orderedWhitelist.contains($0) && !Self.blacklist.contains($0) }
            .sorted()
    }
    
    private var colorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: vitaminsKey)
    }
    
    private var user: User { userService.currentUser }
    
    var body: some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text("Vitamins")
                    .listSectionHeader()
                Spacer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 100)), count: 2), spacing: .spacingDefault) {
                ForEach(Self.orderedWhitelist, id: \.self) { nutrientId in
                    NutrientCell(nutrientId)
                }
                ForEach(otherNutrientIds, id: \.self) { nutrientId in
                    NutrientCell(nutrientId)
                }
            }
        }
    }
    
    @ViewBuilder private func NutrientCell(_ nutrientId: String) -> some View {
        let nutrients = aggregator.nutrientsByNutrientNumber[nutrientId]
        let name = FdcNutrientGroupMapper.nutrientDisplayNames[nutrientId] ?? nutrients?.first?.nutrient.name ?? nutrientId
        let amount = nutrients?.reduce(into: 0.0, { $0 += $1.nutrient.amount }) ?? 0
        let unit = nutrients?.first?.nutrient.unitName ?? ""
        let rdi = rdiLibrary.getRdis(nutrientId)?.getRdi(user)
        
        VStack {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            HStack {
                Text("\(amount.formatted(maxDigits: 0))\(unit)")
                    .contentTransition(.numericText())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .background(alignment: .trailing) {
            AmountCircle(amount, rdi: rdi)
        }
        .padding()
        .inCard(backgroundColor: colorPalette.accent)
    }
    
    @ViewBuilder private func AmountCircle(_ amount: Double, rdi: LifeStageNutrientRdi?) -> some View {
        let lineWidth: CGFloat = 6

        if let rdi {
            let iconName = (amount > rdi.upperLimit) ? "exclamationmark" : (amount > rdi.recommendedAmount) ? "flag.fill" : ""
            let iconColor = (amount > rdi.upperLimit) ? Color.red.opacity(0.9) : colorPalette.accent.opacity(0.6)
                
            Circle()
                .stroke(style: .init(
                    lineWidth: lineWidth,
                ))
                .foregroundStyle(colorPalette.accent.opacity(0.2))
                .overlay {
                    Circle()
                        .trim(from: 0, to: CGFloat(amount) / rdi.recommendedAmount)
                        .stroke(style: .init(
                            lineWidth: lineWidth,
                            lineCap: .round
                        ))
                        .foregroundStyle(colorPalette.accent)
                        .rotationEffect(.degrees(-90))
                }
                .overlay {
                    if amount > rdi.upperLimit {
                        Circle()
                            .trim(from: 0, to: (CGFloat(amount) - rdi.upperLimit) / rdi.upperLimit)
                            .stroke(style: .init(
                                lineWidth: lineWidth,
                                lineCap: .round
                            ))
                            .foregroundStyle(iconColor)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .overlay {
                    Image(systemName: iconName)
                        .bold()
                        .foregroundStyle(iconColor)
                }
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {UsdaNutrientRdiLibrary.create()}
    let _ = swinjectContainer.autoregister(UserService.self) {MockUserService(currentUser: .sample)}

    let sampleFoods = FoodItem.sampleFoods
    
    ScrollView {
        VStack {
            DashboardVitaminsSection(
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
