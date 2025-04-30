//
//  NutrientLibraryDetailView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import SwiftUI
import SwinjectAutoregistration

struct NutrientLibraryDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    let nutrient: Nutrient
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var isExplanationLoaded: Bool = false
    @State private var showExplanation: Bool = false
    @State private var infoString: AttributedString = ""
    @State private var pairs: [NutrientFoodPair] = []
    
    private func loadExplanation() async {
        guard NutrientExplanationMaker.canMakeFor(nutrient.fdcNumber) else {
            isExplanationLoaded = false
            return
        }

        do {
            infoString = try await NutrientExplanationMaker.make(nutrient.fdcNumber)
            isExplanationLoaded = true
        } catch {
            print("Failed to load explanation for \(nutrient.name): \(error)")
        }
    }
    
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
            NativeAdListRow(ad: $ad, size: .medium)
            Section(header: Text("Foods containing \(nutrient.name)")) {
                ForEach(pairs) { pair in
                    FoodRow(pair)
                }
            }
        }
        .listDefaultModifiers()
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: pairs)
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .task { await fetchFoodItems() }
        .task { await loadExplanation() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(nutrient.name)
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            InfoButton()
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func InfoButton() -> some View {
        NavigationLink {
            NutrientInfoView(
                nutrientName: nutrient.name,
                infoString: infoString
            )
        } label: {
            Image(systemName: showExplanation ? "x.circle" : "info.circle")
        }
        .disabled(!isExplanationLoaded)
        .opacity(isExplanationLoaded ? 1 : 0)
        .animation(.snappy, value: isExplanationLoaded)
        .animation(.snappy, value: showExplanation)
    }
    
    @ViewBuilder private func FoodRow(_ pair: NutrientFoodPair) -> some View {
        NavigationLink {
            FoodDetailsView(
                mode: .searchResult(fdcId: pair.food.fdcId),
                onFoodSaved: FoodSaver.forConsumedFoods(modelContext: modelContext).saveFoodItem
            )
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
    .environmentObject(AdProviderFactory.forDev)
}
