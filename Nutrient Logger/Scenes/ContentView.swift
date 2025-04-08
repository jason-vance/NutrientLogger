//
//  ContentView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/6/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var isSetup: Bool = false
    
    var body: some View {
        AppSetupRouter()
            .animation(.snappy, value: isSetup)
    }
    
    @ViewBuilder private func AppSetupRouter() -> some View {
        ZStack {
            if isSetup {
                NavigationStack {
                    Text("Is Setup")
                }
            } else {
                AppSetupView(isSetup: $isSetup)
            }
        }
    }

}

#Preview {
    ContentView()
}
