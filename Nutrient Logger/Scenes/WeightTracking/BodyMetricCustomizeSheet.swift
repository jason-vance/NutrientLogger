//
//  BodyMetricCustomizeSheet.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/2/26.
//

import SwiftUI

struct BodyMetricCustomizeSheet: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("bodyMetricOrder") private var orderRaw: String = BodyMetric.defaultOrder
    @AppStorage("bodyMetric_weight_enabled") private var weightEnabled: Bool = true
    @AppStorage("bodyMetric_bodyFat_enabled") private var bodyFatEnabled: Bool = true
    @AppStorage("bodyMetric_bmi_enabled") private var bmiEnabled: Bool = true
    @AppStorage("bodyMetric_waist_enabled") private var waistEnabled: Bool = true

    @State private var metrics: [BodyMetric] = []

    private func enabledBinding(for metric: BodyMetric) -> Binding<Bool> {
        switch metric {
        case .weight: return $weightEnabled
        case .bodyFat: return $bodyFatEnabled
        case .bmi: return $bmiEnabled
        case .waist: return $waistEnabled
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(metrics) { metric in
                        HStack {
                            Toggle("", isOn: enabledBinding(for: metric))
                                .labelsHidden()
                            Text(metric.displayName)
                            Spacer()
                        }
                    }
                    .onMove { from, to in
                        metrics.move(fromOffsets: from, toOffset: to)
                        orderRaw = metrics.map(\.rawValue).joined(separator: ",")
                    }
                } footer: {
                    Text("Drag to reorder. Disabled metrics are hidden from the Body tab.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                metrics = BodyMetric.ordered(from: orderRaw)
            }
        }
    }
}

#Preview {
    BodyMetricCustomizeSheet()
}
