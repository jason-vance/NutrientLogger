//
//  AppSetupView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI

struct AppSetupView: View {
    
    @Binding var isSetup: Bool
    
    private func waitForSetup() {
        Task {
            await withTaskGroup(of: Void.self, body: { group in
                group.addTask {
                    try? await Task.sleep(for: .seconds(0.75))
                }
                group.addTask {
                    await AppSetup.doSetup()
                }
            })
            
            isSetup = true
        }
    }
    
    var body: some View {
        let imageName = "splash00\(Int.random(in: 0..<5))"
        Image(imageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .onAppear { waitForSetup() }
    }
}

#Preview {
    var isSetup = false
    
    AppSetupView(isSetup: .init(
        get: { isSetup },
        set: { isSetup = $0 }
    ))
}
