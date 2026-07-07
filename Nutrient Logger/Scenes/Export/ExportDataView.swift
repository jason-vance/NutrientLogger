//
//  ExportDataView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/7/26.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

struct ExportDataView: View {

    private enum Preset: String, CaseIterable, Identifiable {
        case last7Days = "7 Days"
        case last30Days = "30 Days"
        case last90Days = "90 Days"
        case allTime = "All Time"

        var id: String { rawValue }
    }

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var engagementAnalytics: EngagementAnalytics

    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now
    @State private var endDate: Date = .now
    @State private var isExporting: Bool = false
    @State private var exportedFileURL: URL?
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    private func applyPreset(_ preset: Preset) {
        switch preset {
        case .last7Days:
            startDate = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
        case .last30Days:
            startDate = Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now
        case .last90Days:
            startDate = Calendar.current.date(byAdding: .day, value: -89, to: .now) ?? .now
        case .allTime:
            startDate = Calendar.current.date(byAdding: .year, value: -10, to: .now) ?? .now
        }
        endDate = .now
        exportedFileURL = nil
    }

    private func exportCsv() {
        guard let start = SimpleDate(date: startDate), let end = SimpleDate(date: endDate), start <= end else { return }

        isExporting = true
        exportedFileURL = nil

        Task {
            let descriptor = FetchDescriptor<ConsumedFood>(
                predicate: #Predicate { food in
                    food.dateLogged >= start && food.dateLogged <= end
                }
            )
            let consumedFoods = (try? modelContext.fetch(descriptor)) ?? []

            let service = CsvExportService(remoteDatabase: remoteDatabase)
            let csv = service.generateCsv(consumedFoods: consumedFoods)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("NutrientLogger-Export-\(start)-\(end)")
                .appendingPathExtension("csv")

            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                await MainActor.run {
                    exportedFileURL = url
                    isExporting = false
                    engagementAnalytics.dataExported(foodCount: consumedFoods.count)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }

    var body: some View {
        List {
            DateRangeSection()
            PresetsSection()
            ExportSection()
        }
        .listDefaultModifiers()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { Toolbar() }
        .alert("Export Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Export Data")
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

    @ViewBuilder private func DateRangeSection() -> some View {
        Section {
            DatePicker("Start Date", selection: $startDate, in: ...endDate, displayedComponents: .date)
                .onChange(of: startDate) { exportedFileURL = nil }
            DatePicker("End Date", selection: $endDate, in: startDate...Date.now, displayedComponents: .date)
                .onChange(of: endDate) { exportedFileURL = nil }
        } header: {
            Text("Date Range")
        }
    }

    @ViewBuilder private func PresetsSection() -> some View {
        Section {
            ForEach(Preset.allCases) { preset in
                Button(preset.rawValue) { applyPreset(preset) }
            }
        }
    }

    @ViewBuilder private func ExportSection() -> some View {
        Section {
            if isExporting {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let exportedFileURL {
                ShareLink(item: exportedFileURL) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Button("Generate CSV") { exportCsv() }
            }
        } footer: {
            Text("Includes every logged food and its full nutrient breakdown for the selected date range.")
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        ExportDataView()
    }
}
