//
//  DashboardView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/7/25.
//

import SwiftUI

struct DashboardView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    var navigationTitle: String {
        let date = Date.now
        
        let hour = Calendar.current.component(.hour, from: date)
        
        if hour >= 0 && hour < 12 {
            return "Good Morning"
        } else if hour >= 12 && hour < 16 {
            return "Good Afternoon"
        } else if hour >= 16 && hour < 22 {
            return "Good Evening"
        } else {
            return "Up Late?"
        }
    }
    
    var body: some View {
        List {
            
        }
        .toolbar { Toolbar() }
        .navigationTitle(Text(navigationTitle))
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Hello")
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
