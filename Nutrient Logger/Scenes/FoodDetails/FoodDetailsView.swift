//
//  FoodDetailsView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/8/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

//TODO: Add a toast-like notification for when a food is successfully saved
struct FoodDetailsView: View {
    
    enum Mode {
        case searchResult(fdcId: Int)
        case loggedFood(food: ConsumedFood)
        case customFood(food: CustomFood)

        var isLoggedFood: Bool {
            if case .loggedFood = self { return true }
            return false
        }

        var isCustomFood: Bool {
            if case .customFood = self { return true }
            return false
        }
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject private var dataController: DataController
    @EnvironmentObject private var customFoodDatabase: CustomFoodDatabase
    
    @State private var prototypeFood: FoodItem?
    @State private var food: FoodItem?
    
    @State private var portions: [Portion] = []
    @State private var selectedPortion: Portion?
    @State private var portionAmountValue: Double = 1
    // Typed text, read on every keystroke so tapping ✓ mid-edit saves what's on screen.
    @State private var amountText: String = "1"
    @State private var amountSelection: TextSelection?
    @FocusState private var isAmountFocused: Bool
    
    @State private var selectedMealTime: MealTime

    @State private var logDate: SimpleDate
    @State private var showDatePicker: Bool = false

    /// What was logged last time for this food, so the card can say when it's reusing it.
    @State private var lastLogged: LogPortionDefaults.LastLogged?

    /// The portion picked when the screen opened. Long portion lists show it and a few others,
    /// and fixing it here keeps those pills from moving around as you tap.
    @State private var featuredAnchor: Portion?
    @State private var showAllPortions: Bool = false

    @State private var showDeleteConfirmation: Bool = false
    @State private var showDeleteCustomFoodConfirmation: Bool = false
    @State private var showEditCustomFood: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    
    let mode: Mode
    let askForDateAndMealTime: Bool
    let onFoodSaved: (FoodItem, Portion) throws -> Void

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var userService: UserService
    @Inject private var rdiLibrary: NutrientRdiLibrary
    @Inject private var engagementAnalytics: EngagementAnalytics

    private var fdcId: Int {
        switch mode {
        case .searchResult(let fdcId):
            return fdcId
        case .loggedFood(let food):
            return food.fdcId
        case .customFood(let food):
            return food.customFoodId
        }
    }
    
    private var customFoodToEdit: CustomFood? {
        guard case .customFood(let food) = mode else { return nil }
        return customFoodDatabase.getFood(withId: food.customFoodId) ?? food
    }

    private var user: User { userService.currentUser }
    
    private func show(alert: String) {
        showAlert = true
        alertTitle = alert
    }
    
    private func fetchFoodAndPortions() {
        if case .customFood(let customFood) = mode {
            // Always look up fresh from database so edits are reflected immediately.
            let fresh = customFoodDatabase.getFood(withId: customFood.customFoodId) ?? customFood
            prototypeFood = fresh.toFoodItem()
            applyInitialSelection(portions: [fresh.toPortion(), .defaultPortion])
            return
        }

        do {
            prototypeFood = try remoteDatabase.getFood(String(fdcId))
            if let food = prototypeFood {
                let portions = try remoteDatabase.getPortions(food)
                applyInitialSelection(portions: LogPortionDefaults.ordered(portions, foodName: food.name))
            } else {
                print("Failed to find remote food with id \(fdcId)")
            }
        } catch {
            print("Failed to fetch remote food with id \(fdcId): \(error.localizedDescription)")
        }
    }

    /// New logs start from the portion and amount used last time for this food, if any.
    /// Editing a logged food keeps its own values (see `populateFieldsIfNeeded`).
    private func applyInitialSelection(portions: [Portion]) {
        let lastLogged = mode.isLoggedFood ? nil : lastLoggedPortion()
        self.lastLogged = lastLogged
        let selection = LogPortionDefaults.initialSelection(portions: portions, lastLogged: lastLogged)
        self.portions = selection.portions
        selectedPortion = selection.selected
        featuredAnchor = selection.selected
        if mode.isLoggedFood {
            if let portion = selectedPortion {
                food = try? prototypeFood?.applyingPortion(portion)
            }
        } else {
            setAmount(selection.amount)
            applyPortion()
        }
    }

    private func lastLoggedPortion() -> LogPortionDefaults.LastLogged? {
        let id = fdcId
        var descriptor = FetchDescriptor<ConsumedFood>(
            predicate: #Predicate { $0.fdcId == id },
            sortBy: [SortDescriptor(\.created, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let last = try? modelContext.fetch(descriptor).first else { return nil }
        return LogPortionDefaults.LastLogged(
            portionName: last.portionName,
            gramWeight: last.portionGramWeight,
            amount: last.portionAmount
        )
    }

    private func setAmount(_ amount: Double) {
        portionAmountValue = amount
        if LogPortionDefaults.parseAmount(amountText) != amount {
            amountText = LogPortionDefaults.editableText(for: amount)
        }
    }

    private func selectPortion(_ portion: Portion) {
        let amount = LogPortionDefaults.amountAfterSwitching(
            from: selectedPortion,
            to: portion,
            currentAmount: portionAmountValue
        )
        selectedPortion = portion
        setAmount(amount)
        applyPortion()
    }

    private func deleteFood() {
        guard let consumedFood = {
            switch mode {
            case .loggedFood(let food): return food
            default: return nil
            }
        }() else {
            show(alert: "Failed to delete. Food doesn't appear to be a logged food")
            return
        }

        modelContext.delete(consumedFood)
        dataController.updateDailySummary()
        presentationMode.wrappedValue.dismiss()
    }

    private func deleteCustomFood() {
        guard case .customFood(let customFood) = mode else { return }
        customFoodDatabase.delete(customFood)
        engagementAnalytics.customFoodDeleted()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func applyPortion() {
        Task {
            if let portion = selectedPortion {
                selectedPortion = .init(
                    name: portion.name,
                    amount: portionAmountValue,
                    gramWeight: portion.gramWeight
                )
                
                do {
                    food = try prototypeFood?.applyingPortion(selectedPortion!)
                } catch {
                    print("Failed to apply portion. Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var portionGrams: String {
        guard let food = food, food.amount > 0 else {
            return "(100g)"
        }
        
        let number = (food.amount * food.gramWeight).formatted(maxDigits: 2)
        return "(\(number)g)"
    }
    
    private var portionValue: String {
        guard let food = food, food.amount > 0 else {
            return ""
        }
        
        let number = food.amount.formatted(maxDigits: 2)
        let separator = food.portionName.first?.isNumber == true ? "x " : " "
        return "\(number)\(separator)\(food.portionName)"
    }
    
    private var displayNutrients: [Nutrient] {
        food?.nutrientGroups.flatMap { group in
            group.nutrients.compactMap { nutrient in
                (nutrient.amount > 0) ? nutrient : nil
            }
        } ?? []
    }
    
    private var isMealTimeValid: Bool {
        !askForDateAndMealTime || selectedMealTime != .none
    }
    
    private var canSave: Bool {
        isMealTimeValid
    }

    private var portionCalories: Double? {
        food?.nutrientGroups
            .lazy
            .flatMap(\.nutrients)
            .first { $0.fdcNumber == FdcNutrientGroupMapper.NutrientNumber_Energy_KCal }?
            .amount
    }

    private var isSameAsLastTime: Bool {
        LogPortionDefaults.matchesLastTime(portion: selectedPortion, amount: portionAmountValue, lastLogged: lastLogged)
    }

    /// The button says where the food is going, so a wrong meal or day is caught before saving.
    private var logButtonTitle: String {
        if !canSave { return "Pick a meal" }
        if mode.isLoggedFood { return "Save Changes" }
        return askForDateAndMealTime ? "Add to \(selectedMealTime.rawValue)" : "Add Food"
    }

    /// "2 × 1 slice · 160 kcal · Today"
    private var logButtonDetail: String? {
        var parts: [String] = []
        if let portion = selectedPortion {
            parts.append(LogPortionDefaults.summary(amount: portionAmountValue, portionName: portion.name))
        }
        if let calories = portionCalories {
            parts.append("\(calories.formatted(maxDigits: 0)) kcal")
        }
        if askForDateAndMealTime {
            parts.append(logDate.formatted())
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
    
    private func saveFood() {
        guard var food = prototypeFood else {
            show(alert: "`prototypeFood` is nil")
            return
        }
        food.dateLogged = logDate
        food.mealTime = selectedMealTime
        
        let selectedPortion = selectedPortion ?? .defaultPortion
        let portion = Portion(
            name: selectedPortion.name,
            amount: portionAmountValue,
            gramWeight: selectedPortion.gramWeight
        )
        
        do {
            try onFoodSaved(food, portion)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save food item: \(error.localizedDescription)")
        }
    }
    
    private func populateFieldsIfNeeded() {
        if case .loggedFood(let food) = mode {
            self.logDate = food.dateLogged
            self.selectedMealTime = food.mealTime
            self.setAmount(food.portion.amount)
            self.selectedPortion = food.portion
            self.featuredAnchor = food.portion
        }
        // .customFood uses defaults (today / .none meal time / amount = 1)
    }
    
    init(
        mode: Mode,
        askForDateAndMealTime: Bool = true,
        initialDate: SimpleDate = .today,
        initialMealTime: MealTime? = nil,
        onFoodSaved: @escaping (FoodItem, Portion) throws -> Void
    ) {
        self.mode = mode
        self.askForDateAndMealTime = askForDateAndMealTime
        self.onFoodSaved = onFoodSaved
        _selectedMealTime = State(initialValue: initialMealTime ?? .forCurrentTime())
        _logDate = State(initialValue: initialDate)
    }
    
    var body: some View {
        List {
            PremiumCTARow(trigger: .smartPaywall, size: .small)
            FoodName()
            LogDetailsCard()

            if !displayNutrients.isEmpty {
                NutritionFactsSection(
                    nutrients: displayNutrients,
                    portionGrams: portionGrams,
                    portionValue: portionValue
                )
            }
            
            if mode.isLoggedFood {
                DeleteButton()
            }
            if mode.isCustomFood {
                DeleteCustomFoodButton()
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listDefaultModifiers()
        .environment(\.defaultMinListRowHeight, 1)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .safeAreaInset(edge: .bottom) { LogButton() }
        .sheet(isPresented: $showDatePicker) { DatePickerSheet() }
        .onAppear { fetchFoodAndPortions() }
        .onAppear { populateFieldsIfNeeded() }
        .onAppear { engagementAnalytics.screenViewed(screenName: "FoodDetails") }
        .onChange(of: portionAmountValue) { applyPortion() }
        .onChange(of: amountText) { _, text in
            if let value = LogPortionDefaults.parseAmount(text), value != portionAmountValue {
                portionAmountValue = value
            }
        }
        .onChange(of: isAmountFocused) { _, isFocused in
            guard isFocused else { return }
            // Select the whole number so typing replaces it.
            DispatchQueue.main.async {
                amountSelection = TextSelection(range: amountText.startIndex..<amountText.endIndex)
            }
        }
        .confirmationDialog(
            "Delete Food?\n\nAre you sure you want to delete \"\(food?.name ?? "this food")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete", role: .destructive) { deleteFood() }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Delete Custom Food?\n\nThis will remove \"\(food?.name ?? "this food")\" from your saved foods. Logged entries won't be affected.",
            isPresented: $showDeleteCustomFoodConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Delete", role: .destructive) { deleteCustomFood() }
            Button("Cancel", role: .cancel) { }
        }
        .alert(alertTitle, isPresented: $showAlert) { }
        .onChange(of: customFoodDatabase.foods) {
            if mode.isCustomFood { fetchFoodAndPortions() }
        }
        .sheet(isPresented: $showEditCustomFood) {
            if let food = customFoodToEdit {
                NavigationStack {
                    CreateCustomFoodView(existingFood: food)
                }
                .environmentObject(customFoodDatabase)
            }
        }
    }

    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Food Details")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if mode.isCustomFood {
                Button {
                    showEditCustomFood = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrow.backward")
        }
    }
    
    @ViewBuilder private func DeleteButton() -> some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Spacer()
                Text("Delete")
                    .foregroundStyle(.red)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func DeleteCustomFoodButton() -> some View {
        Button {
            showDeleteCustomFoodConfirmation = true
        } label: {
            HStack {
                Spacer()
                Text("Delete Custom Food")
                    .foregroundStyle(.red)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
    
    /// The main action, which reads back what will be logged, like "Show 41 homes" instead of "Search".
    @ViewBuilder private func LogButton() -> some View {
        Button {
            saveFood()
        } label: {
            VStack(spacing: 2) {
                Text(logButtonTitle)
                    .font(.headline)
                    .contentTransition(.numericText())
                if let detail = logButtonDetail {
                    Text(detail)
                        .font(.footnote)
                        .opacity(0.85)
                        .contentTransition(.numericText())
                }
            }
            .animation(.snappy, value: logButtonTitle)
            .animation(.snappy, value: logButtonDetail)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(canSave ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.gray.opacity(0.5)))
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder private func FoodName() -> some View {
        HStack {
            Text(food?.name ?? "Food Name")
                .font(.title.bold())
                .listRowDefaultModifiers()
            Spacer()
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func LogDetailsCard() -> some View {
        VStack(spacing: 0) {
            if askForDateAndMealTime {
                DateField()
                Divider().padding(.horizontal)
                MealTimeField()
                Divider().padding(.horizontal)
            }
            PortionField()
            Divider().padding(.horizontal)
            PortionAmountField()
        }
        .padding(.vertical, 4)
        .inCard(backgroundColor: Color.gray)
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func PortionField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                FieldLabel("Portion")
                Spacer()
                if isSameAsLastTime {
                    Label("Same as last time", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            let labels = LogPortionDefaults.pillLabels(for: portions)
            let shown = showAllPortions
                ? Array(portions.indices)
                : LogPortionDefaults.featuredPortionIndices(portions, anchor: featuredAnchor)
            PillRow(
                items: shown,
                labels: shown.map { labels[$0] },
                isSelected: { LogPortionDefaults.isSamePortion(selectedPortion, portions[$0]) },
                onSelect: { selectPortion(portions[$0]) },
                moreCount: portions.count - shown.count,
                onMore: { withAnimation(.snappy) { showAllPortions = true } }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder private func PortionAmountField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                FieldLabel("Amount")
                Spacer()
                TextField("Amount", text: $amountText, selection: $amountSelection)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .multilineTextAlignment(.center)
                    .bold()
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 80, height: 34)
                    .background(Capsule().fill(Color.gray.opacity(0.18)))
                    .overlay(
                        Capsule().stroke(isAmountFocused ? Color.accentColor : .clear, lineWidth: 1.5)
                    )
            }
            PillRow(
                items: LogPortionDefaults.quickAmounts(for: selectedPortion),
                labels: LogPortionDefaults.quickAmounts(for: selectedPortion).map(LogPortionDefaults.label(for:)),
                isSelected: { $0 == portionAmountValue },
                onSelect: { amount in
                    isAmountFocused = false
                    setAmount(amount)
                }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    /// Tappable choices that wrap onto more lines as needed, so every option stays visible
    /// inside the card.
    @ViewBuilder private func PillRow<Item: Hashable>(
        items: [Item],
        labels: [String],
        isSelected: @escaping (Item) -> Bool,
        onSelect: @escaping (Item) -> Void,
        moreCount: Int = 0,
        onMore: @escaping () -> Void = {}
    ) -> some View {
        FlowLayout(spacing: 8) {
            // Keyed by item so revealing more pills slides new ones in instead of relabeling old ones.
            ForEach(Array(zip(items, labels)), id: \.0) { item, label in
                Button {
                    onSelect(item)
                } label: {
                    Pill(label, isSelected: isSelected(item))
                }
                .buttonStyle(.plain)
            }
            if moreCount > 0 {
                Button(action: onMore) {
                    // Built by hand: a Label here showed only its icon inside FlowLayout.
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("\(moreCount) more")
                    }
                        .font(.subheadline)
                        .fixedSize()
                        .lineLimit(1)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func Pill(_ text: String, isSelected: Bool, font: Font = .subheadline, fillsWidth: Bool = false) -> some View {
        Text(text)
            .font(font.weight(isSelected ? .semibold : .regular))
            .lineLimit(1)
            .minimumScaleFactor(fillsWidth ? 0.7 : 1)
            .padding(.horizontal, fillsWidth ? 6 : 12)
            .padding(.vertical, 7)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.gray.opacity(0.18)))
            )
            .contentShape(Capsule())
    }

    /// Field names stay quiet so the chosen options are what you read first.
    @ViewBuilder private func FieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private enum DateOption: CaseIterable {
        case today, yesterday, other
    }

    /// Today and yesterday cover most logging, so they're one tap. Any other day opens a calendar.
    @ViewBuilder private func DateField() -> some View {
        let today = SimpleDate.today
        let yesterday = today.adding(days: -1)
        let isOtherDay = logDate != today && logDate != yesterday
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel("Date")
            PillRow(
                items: DateOption.allCases,
                labels: ["Today", "Yesterday", isOtherDay ? logDate.formatted() : "Other day…"],
                isSelected: { option in
                    switch option {
                    case .today: return logDate == today
                    case .yesterday: return logDate == yesterday
                    case .other: return isOtherDay
                    }
                },
                onSelect: { option in
                    switch option {
                    case .today: logDate = today
                    case .yesterday: logDate = yesterday
                    case .other: showDatePicker = true
                    }
                }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ViewBuilder private func MealPill(_ mealTime: MealTime, font: Font = .subheadline) -> some View {
        Button {
            selectedMealTime = mealTime
        } label: {
            Pill(mealTime.rawValue, isSelected: selectedMealTime == mealTime, font: font, fillsWidth: true)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func DatePickerSheet() -> some View {
        DatePicker(
            "Date",
            selection: .init(
                get: { logDate.toDate() ?? .now },
                set: { date in
                    if let day = SimpleDate(date: date) { logDate = day }
                    showDatePicker = false
                }
            ),
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder private func MealTimeField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel("Meal")
                .underlined(!canSave, color: .red, lineWidth: 1)
            // Always two rows: each snack sits under the meal it follows.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                MealPill(.breakfast)
                MealPill(.lunch)
                MealPill(.dinner)
                MealPill(.morningSnack, font: .footnote)
                MealPill(.afternoonSnack, font: .footnote)
                MealPill(.eveningSnack, font: .footnote)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) {
        MockNutrientLoggerAnalytics()
    }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) {
        MockEngagementAnalytics()
    }
    let _ = swinjectContainer.autoregister(UserService.self) {
        UserServiceForScreenshots()
    }
    let _ = swinjectContainer.autoregister(NutrientRdiLibrary.self) {
        UsdaNutrientRdiLibrary.create()
    }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) {
        RemoteDatabaseForScreenshots()
    }
    
    NavigationStack {
        FoodDetailsView(
            mode: .searchResult(fdcId: 1234),
            onFoodSaved: { _, _ in }
        )
    }
    .environmentObject(CustomFoodDatabase())
}
