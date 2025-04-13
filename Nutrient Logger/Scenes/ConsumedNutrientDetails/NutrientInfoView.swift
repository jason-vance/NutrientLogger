//
//  NutrientInfoView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import SwiftUI

struct NutrientInfoView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    let nutrientName: String
    let infoString: AttributedString
    
    var body: some View {
        ScrollView {
            Text(infoString)
                .padding()
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("About \(nutrientName)")
                    .bold()
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "arrow.backward")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NutrientInfoView(nutrientName: "Nutrient Name", infoString: "Lots of cool info")
    }
}
