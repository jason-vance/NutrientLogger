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
    @Inject private var remoteDatabase: RemoteDatabase

    let groupKey: String
    let headerText: String
    let aggregator: NutrientDataAggregator

    /// How many nutrients to show before the "More" button. Defaults to 3, but the nutrition-tab
    /// customization (and onboarding personalization) can raise it per group so that every promoted
    /// nutrient stays visible above the fold.
    var previewCount: Int = 3

    @State private var showAll: Bool = false

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

    private var allNutrientIds: [String] {
        orderedWhitelist + otherNutrientIds
    }

    private var visibleNutrientIds: [String] {
        if showAll {
            return allNutrientIds
        }
        return Array(allNutrientIds.prefix(previewCount))
    }

    private var colorPalette: ColorPalette {
        ColorPaletteService.getColorPaletteFor(number: groupKey)
    }

    private var user: User { userService.currentUser }

    private var hasAny: Bool {
        !orderedWhitelist.isEmpty || !otherNutrientIds.isEmpty
    }

    var body: some View {
        if hasAny {
            VStack(spacing: .spacingDefault) {
                HStack {
                    Text(headerText)
                        .listSectionHeader()
                    Spacer()
                }
                NutrientRows()
            }
            .animation(.snappy, value: showAll)
        }
    }

    @ViewBuilder private func NutrientRows() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleNutrientIds.enumerated()), id: \.element) { index, nutrientId in
                if index > 0 {
                    Divider()
                        .padding(.leading, 16)
                }
                CompactNutrientRow(nutrientId)
            }
            if allNutrientIds.count > previewCount {
                Divider()
                    .padding(.leading, 16)
                MoreButton()
            }
        }
        .padding(.vertical, 4)
        .inCard(backgroundColor: .gray)
    }

    @ViewBuilder private func CompactNutrientRow(_ nutrientId: String) -> some View {
        let nutrients = aggregator.nutrientsByNutrientNumber[nutrientId] ?? []
        let nutrient = nutrients.first?.nutrient
            ?? remoteDatabase.getNutrient(withId: nutrientId)
            ?? Nutrient(fdcNumber: nutrientId, name: "Unknown Nutrient", unitName: "")
        let name = FdcNutrientGroupMapper.nutrientDisplayNames[nutrientId] ?? nutrient.name
        let amount = nutrients.reduce(into: 0.0) { $0 += $1.nutrient.amount }
        let rdi = resolvedRdi(for: nutrientId, nutrient: nutrient)
        let percentage = rdi.map { $0.recommendedAmount > 0 ? amount / $0.recommendedAmount : 0 }

        NavigationLink {
            ConsumedNutrientDetailsView(
                nutrient: nutrient,
                nutrientFoodPairs: nutrients
            )
        } label: {
            HStack(spacing: 8) {
                Text(name)
                    .font(.subheadline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let percentage, let rdi {
                    GoalProgressBar(
                        amount: amount,
                        goal: rdi.recommendedAmount,
                        dashedThreshold: rdi.upperLimit,
                        fillColor: progressColor(for: percentage),
                        exceededFillColor: .red.opacity(0.25),
                        exceededOutlineColor: .red
                    )
                    .frame(maxWidth: 120, maxHeight: 6)

                    Text("\(Int(percentage * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(progressColor(for: percentage))
                        .frame(width: 44, alignment: .trailing)
                        .contentTransition(.numericText())
                } else {
                    Text(formatAmount(amount, unit: nutrient.unitName))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(Color.text)
        }
    }

    @ViewBuilder private func MoreButton() -> some View {
        Button {
            showAll.toggle()
        } label: {
            HStack {
                Spacer()
                Text(showAll ? "Less" : "More")
                    .font(.subheadline)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .rotationEffect(.degrees(showAll ? -90 : 90))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func resolvedRdi(for nutrientId: String, nutrient: Nutrient) -> LifeStageNutrientRdi? {
        let rdi = NutrientGoalDefaults.effectiveRdi(
            for: nutrientId,
            user: user,
            rdiLibrary: rdiLibrary
        )
        let foodsUnit = WeightUnit.unitFrom(nutrient)
        if foodsUnit == rdi?.unit { return rdi }
        guard let rdi else { return nil }
        return rdi.convertedTo(foodsUnit)
    }

    private func progressColor(for percentage: Double?) -> Color {
        guard let percentage else { return colorPalette.accent }
        if percentage >= 1.0 { return .green }
        if percentage >= 0.67 { return colorPalette.accent }
        if percentage >= 0.33 { return .orange }
        return .red
    }

    private func formatAmount(_ amount: Double, unit: String) -> String {
        "\(amount.formatted(maxDigits: 1))\(unit)"
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }

    let sampleFoods = FoodItem.sampleFoods

    NavigationStack {
        ScrollView {
            VStack {
                DashboardNutrientsSection(
                    blacklist: [],
                    orderedWhitelist: [
                        FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca,
                        FdcNutrientGroupMapper.NutrientNumber_Iron_Fe,
                        FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg,
                        FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn,
                        FdcNutrientGroupMapper.NutrientNumber_Potassium_K
                    ],
                    groupKey: FdcNutrientGroupMapper.GroupNumber_Minerals,
                    headerText: "Minerals",
                    aggregator: NutrientDataAggregator(sampleFoods)
                )
            }
            .padding(.horizontal)
        }
    }
}
