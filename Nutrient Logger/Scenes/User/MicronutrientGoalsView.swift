//
//  MicronutrientGoalsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/17/26.
//

import SwiftUI
import SwinjectAutoregistration

struct MicronutrientGoalsView: View {

    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary

    @State private var user: User?

    private func fetchUser() {
        self.user = userService.currentUser
    }

    private func saveUser() {
        guard let user else { return }
        Task {
            do {
                try await userService.save(user: user)
            } catch {
                print("Failed to save user: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        List {
            Section(header: Text("Vitamins")) {
                ForEach(Self.vitaminNutrients, id: \.id) { nutrient in
                    GoalRow(nutrientId: nutrient.id, name: nutrient.name)
                }
            }
            Section(header: Text("Minerals")) {
                ForEach(Self.mineralNutrients, id: \.id) { nutrient in
                    GoalRow(nutrientId: nutrient.id, name: nutrient.name)
                }
            }
        }
        .listDefaultModifiers()
        .navigationTitle("Micronutrient Goals")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
    }

    @ViewBuilder private func GoalRow(nutrientId: String, name: String) -> some View {
        let rdi = rdiLibrary.getRdis(nutrientId)?.getRdi(user ?? User())
        let unitName = rdi?.unit.name ?? ""
        let defaultAmount = rdi?.recommendedAmount

        HStack {
            Text(name)
            Spacer()
            TextField(
                defaultAmount.map { "\($0.formatted(maxDigits: 0))\(unitName)" } ?? "—",
                text: goalBinding(for: nutrientId)
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .bold()
            .frame(maxWidth: 80)
            Text(unitName)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
                .frame(minWidth: 30, alignment: .leading)
        }
        .listRowDefaultModifiers()
    }

    private func goalBinding(for nutrientId: String) -> Binding<String> {
        Binding(
            get: {
                if let v = user?.micronutrientGoals[nutrientId] {
                    return "\(v.formatted(maxDigits: 0))"
                }
                return ""
            },
            set: { newValue in
                if newValue.isEmpty {
                    user?.micronutrientGoals.removeValue(forKey: nutrientId)
                } else if let d = Double(newValue) {
                    user?.micronutrientGoals[nutrientId] = d
                }
            }
        )
    }

    private struct NutrientEntry: Identifiable {
        let id: String
        let name: String
    }

    private static let vitaminNutrients: [NutrientEntry] = [
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminA_RAE, name: "Vitamin A"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Thiamin, name: "Thiamin"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Riboflavin, name: "Riboflavin"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Niacin, name: "Niacin"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_PantothenicAcid, name: "Pantothenic Acid"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminB6, name: "Vitamin B6"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Folate_DFE, name: "Folate"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminB12, name: "Vitamin B12"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminC_TotalAscorbicAcid, name: "Vitamin C"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminD_D2_Plus_D3, name: "Vitamin D"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminE_Alpha_Tocopherol, name: "Vitamin E"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_VitaminK_Phylloquinone, name: "Vitamin K"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Choline_Total, name: "Choline"),
    ]

    private static let mineralNutrients: [NutrientEntry] = [
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Calcium_Ca, name: "Calcium"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Copper_Cu, name: "Copper"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Iron_Fe, name: "Iron"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Magnesium_Mg, name: "Magnesium"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Manganese_Mn, name: "Manganese"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Phosphorus_P, name: "Phosphorus"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Potassium_K, name: "Potassium"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Selenium_Se, name: "Selenium"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Sodium_Na, name: "Sodium"),
        .init(id: FdcNutrientGroupMapper.NutrientNumber_Zinc_Zn, name: "Zinc"),
    ]
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self) { MockUserService(currentUser: .sample) }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }

    NavigationStack {
        MicronutrientGoalsView()
    }
}
