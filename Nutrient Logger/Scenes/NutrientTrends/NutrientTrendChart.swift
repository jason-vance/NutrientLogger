//
//  NutrientTrendChart.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/24/26.
//

import SwiftUI
import Charts

struct NutrientTrendChart: View {

    let dailyTotals: [DailyNutrientTotal]
    let rdi: LifeStageNutrientRdi?
    let accentColor: Color
    let unitName: String

    private static let upperLimitProximityThreshold: Double = 0.8

    private var dataMax: Double {
        dailyTotals.map(\.amount).max() ?? 0
    }

    private var upperLimit: Double? {
        guard let rdi else { return nil }
        guard rdi.upperLimit > 0, rdi.upperLimit < .greatestFiniteMagnitude else { return nil }
        guard dataMax >= rdi.upperLimit * Self.upperLimitProximityThreshold else { return nil }
        return rdi.upperLimit
    }

    private var maxValue: Double {
        let rdiMax = max(rdi?.recommendedAmount ?? 0, upperLimit ?? 0)
        return max(dataMax, rdiMax) * 1.1
    }

    private var average: Double {
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.reduce(0) { $0 + $1.amount } / Double(dailyTotals.count)
    }

    private var showDayLabels: Bool {
        dailyTotals.count <= 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ChartView()
                .frame(height: 200)
            Legend()
        }
    }

    @ViewBuilder private func ChartView() -> some View {
        Chart {
            ForEach(dailyTotals) { total in
                if showDayLabels {
                    BarMark(
                        x: .value("Date", total.date.toDate() ?? .now, unit: .day),
                        y: .value("Amount", total.amount)
                    )
                    .foregroundStyle(accentColor.gradient)
                    .cornerRadius(4)
                } else {
                    LineMark(
                        x: .value("Date", total.date.toDate() ?? .now, unit: .day),
                        y: .value("Amount", total.amount)
                    )
                    .foregroundStyle(accentColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", total.date.toDate() ?? .now, unit: .day),
                        y: .value("Amount", total.amount)
                    )
                    .foregroundStyle(accentColor.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
            }

            if let rdi, rdi.recommendedAmount > 0, rdi.recommendedAmount < .greatestFiniteMagnitude {
                RuleMark(y: .value("RDI", rdi.recommendedAmount))
                    .foregroundStyle(Color.text.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Goal: \(rdi.recommendedAmount.formatted(maxDigits: 1))\(unitName)")
                            .font(.caption2)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
            }

            if let ul = upperLimit {
                RuleMark(y: .value("Upper Limit", ul))
                    .foregroundStyle(Color.orange.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Upper Limit: \(ul.formatted(maxDigits: 1))\(unitName)")
                            .font(.caption2)
                            .foregroundStyle(Color.orange.opacity(0.7))
                    }
            }
        }
        .chartYScale(domain: 0...maxValue)
        .chartXAxis {
            if showDayLabels {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    AxisGridLine()
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
    }

    @ViewBuilder private func Legend() -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                Text("Daily intake")
                    .font(.caption2)
                    .foregroundStyle(Color.text.opacity(0.6))
            }
            if let rdi, rdi.recommendedAmount > 0, rdi.recommendedAmount < .greatestFiniteMagnitude {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.text.opacity(0.5))
                        .frame(width: 12, height: 1)
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(Color.text.opacity(0.6))
                }
            }
            if upperLimit != nil {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.orange.opacity(0.7))
                        .frame(width: 12, height: 1)
                    Text("Upper Limit")
                        .font(.caption2)
                        .foregroundStyle(Color.text.opacity(0.6))
                }
            }
        }
    }
}
