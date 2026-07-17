//
//  DataSourcesView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/17/26.
//

import SwiftUI

struct DataSourcesView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Nutrient Logger is built on open nutrition data. Huge thanks to the projects that make it possible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SourceSection(
                    title: "USDA FoodData Central",
                    description: "Whole and survey food nutrition data comes from the U.S. Department of Agriculture's FoodData Central, a public-domain database.",
                    links: [
                        ("Visit FoodData Central", "https://fdc.nal.usda.gov")
                    ]
                )

                SourceSection(
                    title: "Open Food Facts",
                    description: "Barcode-scanned product data comes from Open Food Facts, a collaborative, free, and open database of food products. This data is made available under the Open Database License (ODbL) v1.0.",
                    links: [
                        ("Visit Open Food Facts", "https://world.openfoodfacts.org"),
                        ("Open Database License (ODbL) v1.0", "https://opendatacommons.org/licenses/odbl/1-0/")
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func SourceSection(
        title: String,
        description: String,
        links: [(label: String, url: String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(links, id: \.url) { link in
                if let url = URL(string: link.url) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Text(link.label)
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .inCard(backgroundColor: Color.gray)
    }
}

#Preview {
    NavigationStack {
        DataSourcesView()
    }
}
