//
//  CircleChart.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/30/25.
//

import SwiftUI

struct CircleChart: View {
    
    struct Config {
        let size: CGFloat
        let lineWidth: CGFloat
        let color: Color
        
        init(size: CGFloat = 36, lineWidth: CGFloat = 6, color: Color = .accentColor) {
            self.size = size
            self.lineWidth = lineWidth
            self.color = color
        }
    }
    
    let amount: Double
    let total: Double
    let config: Config
    
    init(amount: Double, total: Double, config: Config = .init()) {
        self.amount = amount
        self.total = total
        self.config = config
    }
    
    var body: some View {
        let progress: CGFloat = amount / total
        
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: config.lineWidth))
                .foregroundStyle(Color.gray.opacity(0.2))
                .frame(width: config.size, height: config.size)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: config.lineWidth, lineCap: .round))
                .foregroundStyle(config.color)
                .frame(width: config.size, height: config.size)
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    CircleChart(amount: 75, total: 100)
}
