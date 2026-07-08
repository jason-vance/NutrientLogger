//
//  ConsumedWaterView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 5/2/25.
//

import SwiftUI
import SwiftData

// MARK: - Wave animation helpers

private struct WaveShape: Shape {
    var progress: CGFloat
    var phase: CGFloat
    var amplitude: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let fillY = rect.height * (1 - max(0, min(1, progress)))
        path.move(to: CGPoint(x: 0, y: fillY + amplitude * sin(phase)))
        var x: CGFloat = 0
        while x <= rect.width {
            let angle = (x / rect.width) * 2 * .pi + phase
            path.addLine(to: CGPoint(x: x, y: fillY + amplitude * sin(angle)))
            x += 2
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct WaterWaveCircle: View {
    let progress: Double
    let totalGrams: Double
    let goalGrams: Double
    let waterUnit: WaterUnit

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let amplitude = size * 0.025

            TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                let phase = CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2)) * .pi

                ZStack {
                    // Background tint
                    Circle()
                        .fill(Color.blue.opacity(0.1))

                    // Back wave (lighter, offset phase)
                    WaveShape(progress: CGFloat(progress), phase: phase + .pi, amplitude: amplitude * 0.8)
                        .fill(Color.blue.opacity(0.35))
                        .clipShape(Circle())

                    // Front wave
                    WaveShape(progress: CGFloat(progress), phase: phase, amplitude: amplitude)
                        .fill(Color.blue.opacity(0.7))
                        .clipShape(Circle())

                    // Circle border
                    Circle()
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 2)

                    // Text overlay
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(progress > 0.5 ? Color.white : Color.blue)
                            .font(.title3)
                        Text(waterUnit.formatted(totalGrams))
                            .font(.title)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .contentTransition(.numericText())
                            .foregroundStyle(progress > 0.5 ? Color.white : Color.primary)
                        Text(waterUnit.rawValue)
                            .font(.caption)
                            .foregroundStyle(progress > 0.5 ? Color.white.opacity(0.8) : Color.secondary)
                        if goalGrams > 0 {
                            Text("of \(waterUnit.formatted(goalGrams)) goal")
                                .font(.caption2)
                                .foregroundStyle(progress > 0.5 ? Color.white.opacity(0.7) : Color.secondary)
                        }
                    }
                }
                .frame(width: size, height: size)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}

// MARK: - Main view

struct ConsumedWaterView: View {

    private struct MealFoods: Identifiable {
        var id: MealTime { mealTime }
        let mealTime: MealTime
        let foods: [FoodItem]
    }

    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var userService: UserService
    @Inject private var premiumAnalytics: PremiumAnalytics

    @AppStorage(WaterUnit.appStorageKey) private var preferredWaterUnitRaw: String = WaterUnit.cups.rawValue

    @Query private var waterEntries: [WaterEntry]

    @State private var showCustomAmountSheet: Bool = false
    @State private var customAmountText: String = ""
    @State private var showMarketingView: Bool = false

    let date: SimpleDate
    let aggregator: NutrientDataAggregator

    init(date: SimpleDate, aggregator: NutrientDataAggregator) {
        self.date = date
        self.aggregator = aggregator
        _waterEntries = Query(filter: #Predicate<WaterEntry> { $0.date == date })
    }

    private var waterUnit: WaterUnit {
        WaterUnit(rawValue: preferredWaterUnitRaw) ?? .cups
    }

    private var directWaterGrams: Double {
        waterEntries.reduce(0) { $0 + $1.amountGrams }
    }

    private var foodWaterGrams: Double {
        aggregator.waterCups * 237
    }

    private var totalWaterGrams: Double {
        foodWaterGrams + directWaterGrams
    }

    private var goalGrams: Double {
        if let custom = userService.currentUser.waterGoalGrams {
            return custom
        }
        if let rdi = rdiLibrary
            .getRdis(FdcNutrientGroupMapper.NutrientNumber_Water)?
            .getRdi(userService.currentUser) {
            return rdi.recommendedAmount
        }
        return 0
    }

    private var waterProgress: Double {
        guard goalGrams > 0 else { return 0 }
        return min(totalWaterGrams / goalGrams, 1.0)
    }

    private var waterMealFoods: [MealFoods] {
        var map: [MealTime: [FoodItem]] = [:]
        aggregator.foods.forEach { map[$0.mealTime ?? .none, default: []].append($0) }
        return map
            .map { MealFoods(mealTime: $0.key, foods: $0.value) }
            .sorted { $0.mealTime < $1.mealTime }
    }

    private func logWater(grams: Double) {
        let entry = WaterEntry(date: date, amountGrams: grams)
        modelContext.insert(entry)
        try? modelContext.save()
    }

    var body: some View {
        List {
            WaveCard()
            TrendsSection()
            QuickLogSection()
            if !waterEntries.isEmpty {
                DirectLogsSection()
            }
            if !waterMealFoods.isEmpty {
                FoodsContainingWaterSection()
            }
        }
        .listDefaultModifiers()
        .navigationTitle("\(date.formatted())'s Water")
        .sheet(isPresented: $showCustomAmountSheet) {
            CustomAmountSheet()
        }
        .fullScreenCover(isPresented: $showMarketingView) {
            MarketingView(trigger: .trendCharts)
        }
    }

    // MARK: - Wave card

    @ViewBuilder private func WaveCard() -> some View {
        HStack {
            Spacer()
            WaterWaveCircle(
                progress: waterProgress,
                totalGrams: totalWaterGrams,
                goalGrams: goalGrams,
                waterUnit: waterUnit
            )
            .frame(width: 240, height: 240)
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowDefaultModifiers()
    }

    // MARK: - Trends

    @ViewBuilder private func TrendsSection() -> some View {
        Section {
            if subscriptionManager.isSubscribed {
                NavigationLink {
                    WaterTrendView(waterUnit: waterUnit)
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color.blue)
                        Text("View Trends")
                        Spacer()
                        Text("7 & 30 Day")
                            .font(.caption)
                            .foregroundStyle(Color.text.opacity(0.5))
                    }
                }
                .listRowDefaultModifiers()
            } else {
                Button {
                    premiumAnalytics.premiumFeatureTapped(feature: "water_trends")
                    showMarketingView = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.text.opacity(0.4))
                        Text("View Trends")
                        Spacer()
                        Text("Premium")
                            .font(.caption)
                            .foregroundStyle(Color.blue)
                    }
                    .foregroundStyle(Color.text)
                }
                .listRowDefaultModifiers()
            }
        } header: {
            Text("Water Trends")
        }
    }

    // MARK: - Quick log

    @ViewBuilder private func QuickLogSection() -> some View {
        Section {
            HStack(spacing: 8) {
                ForEach(waterUnit.quickLogAmounts, id: \.label) { item in
                    Button {
                        withAnimation { logWater(grams: item.grams) }
                    } label: {
                        Text("+ \(item.label)")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    customAmountText = ""
                    showCustomAmountSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxHeight: .infinity)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .listRowDefaultModifiers()
        } header: {
            Text("Quick Log")
        }
    }

    // MARK: - Direct logs

    @ViewBuilder private func DirectLogsSection() -> some View {
        Section {
            ForEach(waterEntries) { entry in
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(Color.blue)
                    Text(waterUnit.formatted(entry.amountGrams))
                    Spacer()
                }
                .listRowDefaultModifiers()
            }
            .onDelete { indexSet in
                indexSet.map { waterEntries[$0] }.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        } header: {
            Text("Logged Today")
        }
    }

    // MARK: - Foods containing water

    @ViewBuilder private func FoodsContainingWaterSection() -> some View {
        Section {
            ForEach(waterMealFoods) { waterMealFood in
                Text(waterMealFood.mealTime.rawValue)
                    .listSubsectionHeader()
                ForEach(Array(waterMealFood.foods.enumerated()), id: \.offset) { _, food in
                    ConsumedNutrientDetailsFoodRow(
                        nutrientNumber: FdcNutrientGroupMapper.NutrientNumber_Water,
                        food: food
                    )
                }
            }
        } header: {
            Text("From Foods")
        }
    }

    // MARK: - Custom amount sheet

    @ViewBuilder private func CustomAmountSheet() -> some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("0", text: $customAmountText)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.accentColor)
                        Text(waterUnit.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    .listRowDefaultModifiers()
                } header: {
                    Text("Amount")
                }
            }
            .listDefaultModifiers()
            .navigationTitle("Log Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { CustomAmountSheetToolbar() }
        }
        .presentationDetents([.height(260)])
    }
    
    @ToolbarContentBuilder private func CustomAmountSheetToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { showCustomAmountSheet = false }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Log") {
                if let amount = Double(customAmountText), amount > 0 {
                    withAnimation { logWater(grams: waterUnit.toGrams(amount)) }
                }
                showCustomAmountSheet = false
            }
            .bold()
            .disabled(Double(customAmountText) == nil || (Double(customAmountText) ?? 0) <= 0)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) { UsdaNutrientRdiLibrary.create() }
    let _ = swinjectContainer.autoregister(UserService.self) { UserServiceForScreenshots() }
    let _ = swinjectContainer.autoregister(PremiumAnalytics.self) { MockPremiumAnalytics() }

    let aggregator = NutrientDataAggregator(FoodItem.sampleFoods)

    NavigationStack {
        ConsumedWaterView(date: .today, aggregator: aggregator)
    }
    .environmentObject(SubscriptionManager(isForScreenshots: true))
    .modelContainer(for: WaterEntry.self, inMemory: true)
}
