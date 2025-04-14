//
//  NavigationFab.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/13/25.
//

import SwiftUI

struct NavigationFab<Content>: View where Content: View {
    
    let systemName: String
    let destination: () -> Content
    
    var body: some View {
        NavigationLink {
            destination()
        } label: {
            Image(systemName: systemName)
                .font(.title)
                .bold()
                .foregroundStyle(.white)
                .padding()
                .frame(width: .fabButtonSize, height: .fabButtonSize)
                .background {
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: .black, radius: .shadowRadiusDefault)
                }
        }
        .padding()
    }
}

#Preview {
    NavigationFab(systemName: "plus") {
        Text("Destination")
    }
}
