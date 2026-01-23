//
//  Nutrient_Logger_Widgets.swift
//  Nutrient Logger Widgets
//
//  Created by Jason Vance on 1/15/26.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    
    @MainActor
    func fetchLatestData() -> [SimpleEntry] {
        let context = DataController.shared.container.mainContext
        let descriptor = FetchDescriptor<DailySummary>()
        let dailySummary = (try? context.fetch(descriptor))?
            .sorted { $0.date > $1.date }
            .first
        
        guard let dailySummary else {
            return [.init(date: .now, calories: 0, carbs: 0, fat: 0, protein: 0)]
        }
        
        return [
            .init(
                date: dailySummary.date,
                calories: dailySummary.calories,
                carbs: dailySummary.carbs,
                fat: dailySummary.fat,
                protein: dailySummary.protein
            )
        ]
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let entries = fetchLatestData()
            if let entry = entries.first {
                completion(entry)
            } else {
                completion(SimpleEntry.init(date: .now, calories: 0, carbs: 0, fat: 0, protein: 0))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let entries = fetchLatestData()
            let tomorrow = Calendar.current.date(byAdding: .hour, value: 24, to: .now)!
            let midnight = Calendar.current.startOfDay(for: tomorrow)
            let timeline = Timeline(entries: entries, policy: .after(midnight))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let carbs: Double
    let fat: Double
    let protein: Double
    let isPlaceholder: Bool = false
    
    init(date: Date, calories: Double, carbs: Double, fat: Double, protein: Double, isPlaceholder: Bool = false) {
        self.date = date
        self.calories = calories
        self.carbs = carbs
        self.fat = fat
        self.protein = protein
    }
    
    static let placeholder = SimpleEntry(date: Date(), calories: 1250, carbs: 100, fat: 50, protein: 100, isPlaceholder: true)
}

struct Nutrient_Logger_WidgetsEntryView : View {
    
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var renderingMode

    var entry: Provider.Entry
    
    @Query private var summaries: [DailySummary]
    
    private var displaySummary: DailySummary? {
        summaries
            .sorted { $0.date > $1.date }
            .first
    }
    
    var lineWidth: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 16
        case .systemMedium: return 16
        default: return 32
        }
    }
    
    var margin: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 4
        case .systemMedium: return 4
        default: return 8
        }
    }
    
    var totalLabelDisplay: MacrosPieChart.Config.TotalLabelDisplay {
        switch widgetFamily {
        case .systemSmall: return .abbreviated
        case .systemMedium: return .abbreviated
        default: return .normal
        }
    }
    
    var showFlameSymbol: Bool {
        switch widgetFamily {
        case .systemSmall: return false
        case .systemMedium: return false
        default: return true
        }
    }

    var body: some View {
        let displaySummary = displaySummary
        let date = displaySummary?.date ?? entry.date
        let calories = displaySummary?.calories ?? entry.calories
        let carbs = displaySummary?.carbs ?? entry.carbs
        let fat = displaySummary?.fat ?? entry.fat
        let protein = displaySummary?.protein ?? entry.protein

        HStack(spacing: 16) {
            VStack(spacing: 0) {
                MacrosPieChart(
                    calories: calories,
                    carbs: carbs,
                    fat: fat,
                    protein: protein,
                    config: MacrosPieChart.Config(
                        lineWidth: lineWidth,
                        margin: margin,
                        totalLabelDisplay: totalLabelDisplay,
                        showFlameSymbol: showFlameSymbol,
                        caloriesFont: .title
                    )
                )
                .overlay {
                    Text(SimpleDate(date: date)?.formatted() ?? "")
                        .font(.caption2.bold())
                        .opacity(0.5)
                        .offset(y: 25)
                }
                .aspectRatio(1, contentMode: .fit)
            }
            if widgetFamily == .systemMedium {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    MacroStat(symbol: "square.fill", color: .indigo, label: "Carbs", amount: entry.carbs, unit: "g")
                    MacroStat(symbol: "circle.fill", color: .red, label: "Fat", amount: entry.fat, unit: "g")
                    MacroStat(symbol: "triangle.fill", color: .green, label: "Protein", amount: entry.protein, unit: "g")
                }
            }
        }
    }
    
    @ViewBuilder private func MacroStat(symbol: String, color: Color, label: String, amount: Double, unit: String) -> some View {
        HStack {
            MacroIcon(name: symbol, color: color)
            VStack(spacing: 0) {
                HStack {
                    Text(label)
                        .font(.caption.bold())
                        .opacity(0.75)
                    Spacer()
                }
                HStack {
                    Text("\(amount.formatted(maxDigits: 0))\(unit)")
                        .contentTransition(.numericText())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder private func MacroIcon(name: String, color: Color) -> some View {
        ZStack {
            Image(systemName: name)
                .resizable()
                .foregroundStyle(color)
                .frame(width: 16, height: 16)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.widgetBackground.opacity(renderingMode == .fullColor ? 1.0 : 0.0))
                    }
                }
                .offset(x: -3, y: 6)
            Image(systemName: name)
                .resizable()
                .foregroundStyle(color)
                .frame(width: 12, height: 12)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.widgetBackground.opacity(renderingMode == .fullColor ? 1.0 : 0.0))
                    }
                }
                .offset(x: 5, y: -1)
            Image(systemName: name)
                .resizable()
                .foregroundStyle(color)
                .frame(width: 9, height: 9)
                .padding(2)
                .background {
                    ZStack {
                        Image(systemName: name)
                            .resizable()
                            .foregroundStyle(Color.widgetBackground.opacity(renderingMode == .fullColor ? 1.0 : 0.0))
                    }
                }
                .offset(x: -2, y: -9)
        }
        .frame(width: 24, height: 32)
    }
}

struct Nutrient_Logger_Widgets: Widget {
    let kind: String = "Nutrient_Logger_Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                Nutrient_Logger_WidgetsEntryView(entry: entry)
                    .containerBackground(.widgetBackground, for: .widget)
            } else {
                Nutrient_Logger_WidgetsEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Macros")
        .description("A dsiplay of your macronutrient intake for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("Small", as: .systemSmall) {
    Nutrient_Logger_Widgets()
} timeline: {
    SimpleEntry(date: .distantPast, calories: 0, carbs: 0, fat: 0, protein: 0)
    SimpleEntry(date: .now, calories: 1250, carbs: 100, fat: 50, protein: 100)
    SimpleEntry(date: .distantFuture, calories: 1700, carbs: 100, fat: 100, protein: 100)
}

#Preview("Medium", as: .systemMedium) {
    Nutrient_Logger_Widgets()
} timeline: {
    SimpleEntry(date: .distantPast, calories: 0, carbs: 0, fat: 0, protein: 0)
    SimpleEntry(date: .now, calories: 1250, carbs: 100, fat: 50, protein: 100)
    SimpleEntry(date: .distantFuture, calories: 1700, carbs: 100, fat: 100, protein: 100)
}
