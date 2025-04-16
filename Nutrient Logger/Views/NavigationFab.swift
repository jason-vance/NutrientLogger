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
            FabLabel(systemName: systemName)
        }
        .padding()
    }
}

struct ButtonFab: View {
    
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            FabLabel(systemName: systemName)
        }
        .padding()
    }
}

fileprivate struct FabLabel: View {
    
    let systemName: String
    
    var body: some View {
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
}

#Preview {
    NavigationFab(systemName: "plus") {
        Text("Destination")
    }
    ButtonFab(systemName: "plus") {
        print("Hello")
    }
}
