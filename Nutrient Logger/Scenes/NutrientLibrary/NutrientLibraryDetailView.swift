//
//  NutrientLibraryDetailView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: MVP: Add nutrient info
struct NutrientLibraryDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    let nutrient: Nutrient
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var infoLoaded: Bool = false
    @State private var pairs: [NutrientFoodPair] = []
    
    private func fetchFoodItems() async {
        do {
            pairs = try remoteDatabase.getFoodsContainingNutrient(nutrient)
                .sorted { $0.nutrient.amount > $1.nutrient.amount }
        } catch {
            print("Failed to fetch food items: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Foods containing \(nutrient.name)")) {
                ForEach(pairs) { pair in
                    FoodRow(pair)
                }
            }
        }
        .listDefaultModifiers()
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: pairs)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .task { await fetchFoodItems() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(nutrient.name)
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func FoodRow(_ pair: NutrientFoodPair) -> some View {
        NavigationLink {
            //TODO: MVP: Navigate to food details
        } label: {
            HStack {
                VStack {
                    HStack {
                        Text(pair.food.name)
                            .bold()
                        Spacer()
                    }
                    HStack {
                        Text("\(pair.food.amount.formatted(maxDigits: 2)) \(pair.food.portionName)")
                        Spacer()
                    }
                }
                Text("\(pair.nutrient.amount.formatted(maxDigits: 2))\(pair.nutrient.unitName)")
            }
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    
    NavigationStack {
        NutrientLibraryDetailView(nutrient: .init(
            fdcNumber: FdcNutrientGroupMapper.NutrientNumber_Thiamin,
            name: "Thiamin",
            unitName: "g"
        ))
    }
}
