//
//  CustomFoodsLibraryView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import SwiftUI

struct CustomFoodsLibraryView: View {

    @Environment(\.presentationMode) private var presentationMode

    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @EnvironmentObject private var customFoodDatabase: CustomFoodDatabase
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    private var displayFoods: [CustomFood] {
        customFoodDatabase.foods.sorted { $0.name < $1.name }
    }

    private func deleteFoods(at offsets: IndexSet) {
        for offset in offsets {
            customFoodDatabase.delete(displayFoods[offset])
        }
    }

    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .medium)
            if displayFoods.isEmpty {
                ContentUnavailableView(
                    "No Custom Foods... Yet!",
                    systemImage: "fork.knife",
                    description: Text("Foods you create are saved to your own personal library, ready to log again anytime. Tap the plus (+) button in the bottom right corner to create your first one!")
                )
                .listRowDefaultModifiers()
            } else {
                Section {
                    ForEach(displayFoods) { food in
                        FoodRow(food)
                    }
                    .onDelete { deleteFoods(at: $0) }
                } header: {
                    HStack {
                        Image(systemName: "fork.knife")
                        Text("My Custom Foods")
                        Spacer()
                    }
                }
            }
            SpaceForFab()
        }
        .listDefaultModifiers()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .animation(.snappy, value: customFoodDatabase.foods)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .overlay(alignment: .bottomTrailing) {
            AddFoodButton()
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("My Custom Foods")
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

    @ViewBuilder private func FoodRow(_ food: CustomFood) -> some View {
        NavigationLink {
            CreateCustomFoodView(existingFood: food)
        } label: {
            Text(food.name)
        }
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func SpaceForFab() -> some View {
        Spacer(minLength: 100)
            .listRowDefaultModifiers()
    }

    @ViewBuilder private func AddFoodButton() -> some View {
        NavigationFab(systemName: "plus") {
            CreateCustomFoodView()
        }
    }
}

#Preview {
    NavigationStack {
        CustomFoodsLibraryView()
    }
    .environmentObject(AdProviderFactory.forDev)
    .environmentObject(CustomFoodDatabase())
}
