//
//  DashboardNutrientsSection.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

struct DashboardNutrientsSection: View {
    
    let blacklist: Set<String>
    let orderedWhitelist: [String]
    
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService

    let groupKey: String
    let headerText: String
    let aggregator: NutrientDataAggregator
    
    private var otherNutrientIds: [String] {
        guard let group = aggregator.nutrientGroups
            .first(where: { $0.fdcNumber == groupKey })
        else {
            return []
        }
        
        return Set(group.nutrients.map(\.fdcNumber))
            .filter { !orderedWhitelist.contains($0) && !blacklist.contains($0) }
            .sorted()
    }
    
    private var colorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: groupKey)
    }
    
    private var user: User { userService.currentUser }
    
    var body: some View {
        VStack(spacing: .spacingDefault) {
            HStack {
                Text(headerText)
                    .listSectionHeader()
                Spacer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 100)), count: 2), spacing: .spacingDefault) {
                ForEach(orderedWhitelist, id: \.self) { nutrientId in
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
                Text("\(amount.formatted(maxDigits: 1))\(unit)")
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
        .inCard(backgroundColor: Color.gray)
    }
    
    @ViewBuilder private func AmountCircle(_ amount: Double, rdi: LifeStageNutrientRdi?) -> some View {
        let lineWidth: CGFloat = 6

        if let rdi {
            let iconName = (amount > rdi.upperLimit) ? "exclamationmark" : (amount > rdi.recommendedAmount) ? "flag.fill" : ""
            let iconColor = (amount > rdi.upperLimit) ? Color.red.opacity(0.9) : colorPalette.accent.opacity(0.6)
            let circleTo = (rdi.recommendedAmount > 0) ? CGFloat(amount) / rdi.recommendedAmount : CGFloat(amount) / rdi.upperLimit
            
            Circle()
                .stroke(style: .init(
                    lineWidth: lineWidth,
                ))
                .foregroundStyle(colorPalette.accent.opacity(0.2))
                .overlay {
                    Circle()
                        .trim(from: 0, to: circleTo)
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
                    } else {
                        Circle()
                            .trim(from: 0, to: (CGFloat(amount) - rdi.recommendedAmount) / rdi.recommendedAmount)
                            .stroke(style: .init(
                                lineWidth: lineWidth,
                                lineCap: .round
                            ))
                            .foregroundStyle(Color.text.opacity(0.2))
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
            DashboardNutrientsSection(
                blacklist: [],
                orderedWhitelist: [
                    FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                    FdcNutrientGroupMapper.NutrientNumber_Iron_Fe
                ],
                groupKey: FdcNutrientGroupMapper.GroupNumber_Minerals,
                headerText: "Testing",
                aggregator: NutrientDataAggregator(sampleFoods)
            )
        }
        .padding(.horizontal)
    }
}
