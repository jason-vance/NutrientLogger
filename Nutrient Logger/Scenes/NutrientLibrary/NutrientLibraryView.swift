//
//  NutrientLibraryView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/16/25.
//

import SwiftUI

struct NutrientLibraryView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Inject private var remoteDatabase: RemoteDatabase
    
    @State private var searchText: String = ""
    @State private var nutrients: [Nutrient] = []
    
    private var displayNutrients: [Nutrient] {
        guard !searchText.isEmpty else {
            return nutrients
        }
        
        let tokens = searchText.split(separator: " ")
        
        return nutrients
            .filter { $0.name.lowercased().caseInsensitiveContainsAny(of: tokens) }
            .sorted { $0.name < $1.name }
    }
    
    private func fetchNutrients() async {
        do {
            nutrients = try remoteDatabase.getAllNutrientsLinkedToFoods()
        } catch {
            print("Error while loading nutrients: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Nutrients")) {
                ForEach(displayNutrients) { nutrient in
                    NutrientRow(nutrient)
                }
            }
        }
        .listDefaultModifiers()
        .searchable(
            text: $searchText,
            prompt: Text("Vitamin A, Protein, DHA...")
        )
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: searchText)
        .animation(.snappy, value: nutrients)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .task { await fetchNutrients() }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Nutrient Library")
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
    
    @ViewBuilder private func NutrientRow(_ nutrient: Nutrient) -> some View {
        NavigationLink {
            //TODO: MVP: Navigate to NutrientLibraryDetailsView
            Text("NutrientLibraryDetailsView")
        } label: {
            HStack {
                Text(nutrient.name)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {RemoteDatabaseForScreenshots()}
    
    NavigationStack {
        NutrientLibraryView()
    }
}
