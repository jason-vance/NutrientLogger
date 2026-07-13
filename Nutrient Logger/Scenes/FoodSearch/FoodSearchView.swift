//
//  FoodSearchView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

struct FoodSearchView: View {
    
    enum SearchFunction {
        case defaultSearchFunction
        case addFoodToMeal

        var shouldIncludeRecentSearches: Bool {
            switch self {
            case .defaultSearchFunction: return false
            case .addFoodToMeal: return false
            }
        }

        var shouldIncludeRecentlyLoggedFoods: Bool {
            switch self {
            case .defaultSearchFunction: return true
            case .addFoodToMeal: return true
            }
        }

        var shouldIncludeFdcFoods: Bool {
            switch self {
            case .defaultSearchFunction: return true
            case .addFoodToMeal: return true
            }
        }

        var shouldIncludeFdcNutrients: Bool {
            switch self {
            case .defaultSearchFunction: return true
            case .addFoodToMeal: return false
            }
        }

        var shouldIncludeUserMeals: Bool {
            switch self {
            case .defaultSearchFunction: return true
            case .addFoodToMeal: return false
            }
        }

        var shouldIncludeCustomFoods: Bool { true }
    }

    enum SearchResult: Identifiable, Equatable {
        case recentSearch(String)
        case recentlyLoggedFood(ConsumedFood)
        case fdcFood(FdcSearchableFood)
        case fdcNutrient(Nutrient)
        case userMeal(UserMealsSearchableMeal)
        case customFood(CustomFood)

        var id: String {
            switch self {
            case .recentSearch(let query): return query
            case .recentlyLoggedFood(let food): return "recentlyLoggedFood-\(food.fdcId)"
            case .fdcFood(let food): return "fdcFood-\(food.fdcId)"
            case .fdcNutrient(let nutrient): return "fdcNutrient-\(nutrient.fdcId)"
            case .userMeal(let meal): return "userMeal-\(meal.meal.id)"
            case .customFood(let food): return "customFood-\(food.customFoodId)"
            }
        }

        var isRecentSearch: Bool {
            if case .recentSearch = self { return true }
            return false
        }

        var isRecentlyLoggedFood: Bool {
            if case .recentlyLoggedFood = self { return true }
            return false
        }

        var isFdcFood: Bool {
            if case .fdcFood = self { return true }
            return false
        }

        var isFdcNutrient: Bool {
            if case .fdcNutrient = self { return true }
            return false
        }

        var isUserMeal: Bool {
            if case .userMeal = self { return true }
            return false
        }

        var isCustomFood: Bool {
            if case .customFood = self { return true }
            return false
        }
    }
    
    struct SearchResultsSection: Identifiable, Equatable {
        var id: String { name }
        let name: String
        let symbol: String
        let results: [SearchResult]
        
        init(name: String, symbol: String, results: [SearchResult]) {
            self.name = name
            self.symbol = symbol
            self.results = results
        }
    }
    
    @Query private var meals: [Meal]
    @Query private var recentSearches: [RecentSearch]

    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var analytics: NutrientLoggerAnalytics
    @Inject private var engagementAnalytics: EngagementAnalytics

    @EnvironmentObject private var customFoodDatabase: CustomFoodDatabase
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isSearching) private var isSearching
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?

    @StateObject private var reviewPrompter = ReviewPrompter()
    @State private var searchText: String = ""
    @State private var hasSearched: Bool = false
    @State private var isLoading: Bool = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil
    
    @State private var searchResults: [SearchResult] = []
    @State private var showCreateCustomFood: Bool = false
    @State private var foodBeingEdited: CustomFood? = nil

    @State private var showBarcodeScanner: Bool = false
    @State private var scannedCustomFood: CustomFood? = nil
    @State private var barcodeProduct: OpenFoodFactsProduct? = nil
    @State private var showBarcodeNotFound: Bool = false
    @State private var isScanningBarcode: Bool = false
    @State private var similarFoods: [FdcSearchableFood] = []
    @State private var selectedSimilarFoodId: Int? = nil

    let searchFunction: SearchFunction
    let askForDateAndMealTime: Bool
    let initialDate: SimpleDate
    let initialMealTime: MealTime?
    let onFoodSaved: (FoodItem, Portion) throws -> Void

    private var groupedSearchResults: [SearchResultsSection] {
        [
            .init(
                name: "Recent Searches",
                symbol: "magnifyingglass",
                results: searchResults.filter {
                    $0.isRecentSearch && searchFunction.shouldIncludeRecentSearches
                }
            ),
            .init(
                name: "Recently Logged",
                symbol: "arrow.clockwise.circle",
                results: searchResults.filter {
                    $0.isRecentlyLoggedFood && searchFunction.shouldIncludeRecentlyLoggedFoods
                }
            ),
            .init(
                name: "My Custom Foods",
                symbol: "pencil.and.list.clipboard",
                results: searchResults.filter {
                    $0.isCustomFood && searchFunction.shouldIncludeCustomFoods
                }
            ),
            .init(
                name: "Nutrients",
                symbol: "atom",
                results: searchResults.filter {
                    $0.isFdcNutrient && searchFunction.shouldIncludeFdcNutrients
                }
            ),
            .init(
                name: "Your Reusable Meals",
                symbol: "frying.pan",
                results: searchResults.filter {
                    $0.isUserMeal && searchFunction.shouldIncludeUserMeals
                }
            ),
            .init(
                name: "Foods",
                symbol: "carrot",
                results: searchResults.filter {
                    $0.isFdcFood && searchFunction.shouldIncludeFdcFoods
                }
            ),
        ]
    }
    
    private func resetViewState() {
        searchText = ""
        hasSearched = false
        searchResults = []
        similarFoods = []
        selectedSimilarFoodId = nil
        fetchInitialSuggestions()
    }
    
    private func fetchInitialSuggestions() {
        if searchResults.isEmpty {
            if searchFunction.shouldIncludeRecentSearches {
                searchResults.append(contentsOf: fetchRecentSearches())
            }
            if searchFunction.shouldIncludeRecentlyLoggedFoods {
                searchResults.append(contentsOf: searchRecentlyLoggedFoods())
            }
            if searchFunction.shouldIncludeCustomFoods {
                searchResults.append(contentsOf: allCustomFoods())
            }
        }
    }
    
    private func fetchRecentSearches() -> [SearchResult] {
        recentSearches
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { SearchResult.recentSearch($0.query) }
    }
    
    private func fetchRecentlyLoggedFoods() -> [ConsumedFood] {
        do {
            var descriptor = FetchDescriptor<ConsumedFood>(
                sortBy: [ .init(\.created, order: .reverse) ]
            )
            descriptor.fetchLimit = 512

            let allRecent = try modelContext.fetch(descriptor)
            let now = Date()
            let grouped = Dictionary(grouping: allRecent, by: \.fdcId)

            return grouped.values.compactMap { foods -> (food: ConsumedFood, score: Double)? in
                guard let mostRecent = foods.max(by: { $0.created < $1.created }) else { return nil }
                let frequency = Double(foods.count)
                let daysSinceLast = now.timeIntervalSince(mostRecent.created) / 86400.0
                let recencyWeight = exp(-0.693 * daysSinceLast / 7.0)
                return (mostRecent, frequency * recencyWeight)
            }
            .sorted { $0.score > $1.score }
            .map(\.food)
        } catch {
            print("Failed to fetch recently logged foods: \(error.localizedDescription)")
        }
        return []
    }
    
    private func doSearch() {
        guard !searchText.isEmpty else { return }

        analytics.foodSearched(searchText)
        
        hasSearched = true
        searchResults = []
        isLoading = true
        Task {
            searchResults = await withTaskGroup(of: Array<SearchResult>.self) { group in
                if searchFunction.shouldIncludeRecentlyLoggedFoods {
                    group.addTask { await self.searchRecentlyLoggedFoods(searchText) }
                }
                if searchFunction.shouldIncludeFdcFoods {
                    group.addTask { await self.searchForRemoteFoods(searchText) }
                }
                if searchFunction.shouldIncludeUserMeals {
                    group.addTask { await self.searchUserMeals(searchText) }
                }
                if searchFunction.shouldIncludeFdcNutrients {
                    group.addTask { await self.searchRemoteNutrients(searchText) }
                }
                if searchFunction.shouldIncludeCustomFoods {
                    group.addTask { await self.searchCustomFoods(searchText) }
                }

                var results: [SearchResult] = []
                for await result in group {
                    results.append(contentsOf: result)
                }
                return results
            }

            if searchResults.isEmpty {
                engagementAnalytics.searchReturnedNoResults(query: searchText)
            } else {
                if let previous = recentSearches.first(where: { $0.query.lowercased() == searchText.lowercased() }) {
                    previous.query = searchText
                    previous.date = .now
                } else {
                    modelContext.insert(RecentSearch(query: searchText, date: .now))
                }
            }

            isLoading = false
        }
        
        promptForReview()
    }
    
    private func searchRemoteNutrients(_ query: String) async -> [SearchResult] {
        do {
            return try remoteDatabase
                .getAllNutrientsLinkedToFoods()
                .filter { $0.name.localizedCaseInsensitiveContains(query) }
                .map { SearchResult.fdcNutrient($0) }
        } catch {
            print("Could not complete nutrient search: \(error.localizedDescription)")
        }
        return []
    }
    
    private func searchForRemoteFoods(_ query: String) async -> [SearchResult] {
        do {
            return try remoteDatabase
                .search(query)
                .map { SearchResult.fdcFood($0) }
        } catch {
            print("Could not complete food search: \(error.localizedDescription)")
        }
        return []
    }
    
    private func searchUserMeals(_ query: String) async -> [SearchResult] {
        let tokens = query.split(separator: " ")
        return meals
            .filter { $0.matchesAll(of: tokens) }
            .map { UserMealsSearchableMeal(meal: $0) }
            .map { SearchResult.userMeal($0) }
    }
    
    private func searchRecentlyLoggedFoods(_ query: String? = nil) -> [SearchResult] {
        let recentlyLogged = fetchRecentlyLoggedFoods()
        let tokens = query?.split(separator: " ") ?? []

        return recentlyLogged
            .filter { tokens.isEmpty || $0.name.caseInsensitiveContainsAll(of: tokens) }
            .map(SearchResult.recentlyLoggedFood)
    }

    private func allCustomFoods() -> [SearchResult] {
        customFoodDatabase.foods
            .sorted { $0.created > $1.created }
            .map { SearchResult.customFood($0) }
    }

    private func searchCustomFoods(_ query: String) async -> [SearchResult] {
        let tokens = query.split(separator: " ")
        return await MainActor.run {
            customFoodDatabase.foods
                .filter { $0.name.caseInsensitiveContainsAll(of: tokens) }
                .sorted { $0.created > $1.created }
                .map { SearchResult.customFood($0) }
        }
    }
    
    private func handleBarcodeDetected(_ barcode: String) {
        if let existing = customFoodDatabase.foods.first(where: { $0.barcode == barcode }) {
            engagementAnalytics.barcodeScanCompleted(found: true)
            showBarcodeScanner = false
            scannedCustomFood = existing
            return
        }

        isScanningBarcode = true
        Task {
            do {
                if let product = try await OpenFoodFactsService.shared.lookupBarcode(barcode) {
                    engagementAnalytics.barcodeScanCompleted(found: true)
                    barcodeProduct = product
                } else {
                    engagementAnalytics.barcodeScanCompleted(found: false)
                    showBarcodeScanner = false
                    showBarcodeNotFound = true
                }
            } catch {
                engagementAnalytics.barcodeScanCompleted(found: false)
                showBarcodeScanner = false
                showBarcodeNotFound = true
            }
            isScanningBarcode = false
        }
    }

    private func saveBarcodeProduct(_ product: OpenFoodFactsProduct) {
        let food = OpenFoodFactsService.shared.toCustomFood(product, database: customFoodDatabase)
        customFoodDatabase.save(food)
        barcodeProduct = nil
        similarFoods = []
        showBarcodeScanner = false
        scannedCustomFood = food
    }

    private func promptForReview() {
        if shouldPromptForReview() {
            reviewPrompter.promptUserForReview()
        }
    }

    private func shouldPromptForReview() -> Bool {
        guard let earliestFood = {
            var descriptor = FetchDescriptor<ConsumedFood>(
                sortBy: [ .init(\.created, order: .forward) ]
            )
            descriptor.fetchLimit = 1
            return try? modelContext.fetch(descriptor).first
        }() else {
            return false
        }
        
        guard let mostRecentFood = {
            var descriptor = FetchDescriptor<ConsumedFood>(
                sortBy: [ .init(\.created, order: .reverse) ]
            )
            descriptor.fetchLimit = 1
            return try? modelContext.fetch(descriptor).first
        }() else {
            return false
        }
        
        let timeDiff = abs(mostRecentFood.created.distance(to: earliestFood.created))
        let roughlyOneDay = TimeInterval.fromDays(0.5)
        return timeDiff > roughlyOneDay
    }
    
    init(
        searchFunction: SearchFunction = .defaultSearchFunction,
        askForDateAndMealTime: Bool = true,
        initialDate: SimpleDate = .today,
        initialMealTime: MealTime? = nil,
        onFoodSaved: @escaping (FoodItem, Portion) throws -> Void
    ) {
        self.searchFunction = searchFunction
        self.askForDateAndMealTime = askForDateAndMealTime
        self.initialDate = initialDate
        self.initialMealTime = initialMealTime
        self.onFoodSaved = onFoodSaved
    }
    
    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .medium)
            if searchResults.isEmpty && hasSearched && !isLoading {
                ContentUnavailableView(
                    "\"\(searchText)\"",
                    systemImage: "square.dashed",
                    description: Text("Nothing was found. Try a different term, or add it as a custom food.")
                )
                .listRowDefaultModifiers()
                Button {
                    showCreateCustomFood = true
                } label: {
                    Label("Create Custom Food", systemImage: "plus.circle")
                }
                .listRowDefaultModifiers()
            } else {
                ForEach(groupedSearchResults) { searchResultGroup in
                    if !searchResultGroup.results.isEmpty {
                        Section {
                            ForEach(searchResultGroup.results) { searchResult in
                                SearchResultRow(searchResult)
                            }
                        } header: {
                            HStack {
                                Image(systemName: searchResultGroup.symbol)
                                Text(searchResultGroup.name)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .listDefaultModifiers()
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .animation(.snappy, value: searchText)
        .animation(.snappy, value: searchResults)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Foods, Meals, Nutrients...")
        )
        .onChange(of: searchText) {
            hasSearched = false
            searchDebounceTask?.cancel()
            if searchText.isEmpty {
                resetViewState()
            } else {
                searchDebounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    doSearch()
                }
            }
        }
        .onChange(of: customFoodDatabase.foods) {
            searchResults.removeAll { $0.isCustomFood }
            if searchText.isEmpty {
                searchResults.append(contentsOf: allCustomFoods())
            } else if hasSearched {
                let tokens = searchText.split(separator: " ")
                let fresh = customFoodDatabase.foods
                    .filter { $0.name.caseInsensitiveContainsAll(of: tokens) }
                    .sorted { $0.created > $1.created }
                    .map { SearchResult.customFood($0) }
                searchResults.append(contentsOf: fresh)
            }
        }
        .onSubmit(of: .search) {
            searchDebounceTask?.cancel()
            doSearch()
        }
        .onAppear { fetchInitialSuggestions() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Toolbar() }
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .reviewPromptAlert(prompter: reviewPrompter)
        .sheet(isPresented: $showCreateCustomFood) {
            NavigationStack {
                CreateCustomFoodView()
            }
            .environmentObject(customFoodDatabase)
        }
        .sheet(item: $foodBeingEdited) { food in
            NavigationStack {
                CreateCustomFoodView(existingFood: food)
            }
            .environmentObject(customFoodDatabase)
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerSheet(
                barcodeProduct: $barcodeProduct,
                isScanningBarcode: $isScanningBarcode,
                similarFoods: similarFoods,
                onBarcodeDetected: handleBarcodeDetected,
                onSaveProduct: saveBarcodeProduct,
                onCancelReview: {
                    barcodeProduct = nil
                    similarFoods = []
                },
                onSelectSimilarFood: { food in
                    showBarcodeScanner = false
                    barcodeProduct = nil
                    similarFoods = []
                    selectedSimilarFoodId = food.fdcId
                }
            )
        }
        .onChange(of: barcodeProduct) { _, newProduct in
            similarFoods = []
            guard let product = newProduct else { return }
            Task {
                do {
                    similarFoods = try remoteDatabase.searchSimilar(
                        productName: product.name,
                        brand: product.brand,
                        limit: 7
                    )
                } catch {
                    print("Similar food search failed: \(error.localizedDescription)")
                }
            }
        }
        .alert("Product Not Found", isPresented: $showBarcodeNotFound) {
            Button("Search Manually") {
                engagementAnalytics.barcodeFallbackTaken(path: "manual_search")
            }
            Button("Create Custom Food") {
                engagementAnalytics.barcodeFallbackTaken(path: "custom_food")
                showCreateCustomFood = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This barcode wasn't found in the database. You can search for the food manually or create a custom food entry.")
        }
        .navigationDestination(item: $scannedCustomFood) { food in
            FoodDetailsView(
                mode: .customFood(food: food),
                askForDateAndMealTime: askForDateAndMealTime,
                initialDate: initialDate,
                initialMealTime: initialMealTime,
                onFoodSaved: { foodItem, portion in
                    try onFoodSaved(foodItem, portion)
                    resetViewState()
                }
            )
        }
        .navigationDestination(item: $selectedSimilarFoodId) { fdcId in
            FoodDetailsView(
                mode: .searchResult(fdcId: fdcId),
                askForDateAndMealTime: askForDateAndMealTime,
                initialDate: initialDate,
                initialMealTime: initialMealTime,
                onFoodSaved: { foodItem, portion in
                    try onFoodSaved(foodItem, portion)
                    resetViewState()
                }
            )
        }
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Search")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    engagementAnalytics.barcodeScanInitiated()
                    showBarcodeScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                }
                Button {
                    showCreateCustomFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    @ViewBuilder private func BackButton() -> some View {
        if searchFunction == .addFoodToMeal {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    @ViewBuilder private func SearchResultRow(_ searchResult: SearchResult) -> some View {
        switch searchResult {
        case .recentSearch(let query):
            RecentSearchRow(query)
        case .recentlyLoggedFood(let food):
            RecentlyLoggedFoodRow(food)
        case .fdcFood(let food):
            FdcFoodRow(food)
        case .fdcNutrient(let nutrient):
            FdcNutrientRow(nutrient)
        case .userMeal(let meal):
            UserMealRow(meal)
        case .customFood(let food):
            CustomFoodRow(food)
        }
    }
    
    @ViewBuilder private func RecentSearchRow(_ query: String) -> some View {
        Button {
            searchText = query
            doSearch()
        } label: {
            HStack {
                Text(query)
                Spacer()
                Image(systemName: "arrow.up.backward.square")
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func RecentlyLoggedFoodRow(_ food: ConsumedFood) -> some View {
        NavigationLink {
            FoodDetailsView(
                mode: .searchResult(fdcId: food.fdcId),
                askForDateAndMealTime: askForDateAndMealTime,
                initialDate: initialDate,
                initialMealTime: initialMealTime,
                onFoodSaved: onFoodSaved
            )
        } label: {
            HStack {
                Text(food.name)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FdcFoodRow(_ food: FdcSearchableFood) -> some View {
        NavigationLink {
            FoodDetailsView(
                mode: .searchResult(fdcId: food.fdcId),
                askForDateAndMealTime: askForDateAndMealTime,
                initialDate: initialDate,
                initialMealTime: initialMealTime,
                onFoodSaved: { foodItem, portion in
                    try onFoodSaved(foodItem, portion)
                    resetViewState()
                }
            )
        } label: {
            HStack {
                Text(food.description)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FdcNutrientRow(_ nutrient: Nutrient) -> some View {
        NavigationLink {
            NutrientLibraryDetailView(nutrient: nutrient)
        } label: {
            HStack {
                Text(nutrient.name)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func UserMealRow(_ meal: UserMealsSearchableMeal) -> some View {
        NavigationLink {
            LogMealView(meal: meal.meal)
        } label: {
            HStack {
                Text(meal.mealName)
                Spacer()
            }
        }
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func CustomFoodRow(_ food: CustomFood) -> some View {
        NavigationLink {
            FoodDetailsView(
                mode: .customFood(food: food),
                askForDateAndMealTime: askForDateAndMealTime,
                initialDate: initialDate,
                initialMealTime: initialMealTime,
                onFoodSaved: { foodItem, portion in
                    try onFoodSaved(foodItem, portion)
                    resetViewState()
                }
            )
        } label: {
            HStack {
                Text(food.name)
                Spacer()
                Image(systemName: "pencil.and.list.clipboard")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .listRowDefaultModifiers()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                customFoodDatabase.delete(food)
                searchResults.removeAll { $0.id == SearchResult.customFood(food).id }
                engagementAnalytics.customFoodDeleted()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                foodBeingEdited = food
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.accentColor)
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }
    let _ = swinjectContainer.autoregister(EngagementAnalytics.self) { MockEngagementAnalytics() }

    NavigationStack {
        FoodSearchView(onFoodSaved: FoodSaver.mock.saveFoodItem)
    }
    .environmentObject(AdProviderFactory.forDev)
    .environmentObject(CustomFoodDatabase())
}

// MARK: - Barcode Scanner Sheet

private struct BarcodeScannerSheet: View {

    @Binding var barcodeProduct: OpenFoodFactsProduct?
    @Binding var isScanningBarcode: Bool

    let similarFoods: [FdcSearchableFood]
    let onBarcodeDetected: (String) -> Void
    let onSaveProduct: (OpenFoodFactsProduct) -> Void
    let onCancelReview: () -> Void
    let onSelectSimilarFood: (FdcSearchableFood) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if let product = barcodeProduct {
                BarcodeProductReviewView(
                    product: product,
                    similarFoods: similarFoods,
                    onSave: { onSaveProduct(product) },
                    onCancel: onCancelReview,
                    onSelectSimilarFood: onSelectSimilarFood
                )
            } else {
                BarcodeScannerView(onBarcodeDetected: onBarcodeDetected)
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    }

                    Spacer()

                    Text("Point your camera at a barcode")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 60)
                }
            }

            if isScanningBarcode {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Looking up product...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }
        }
        .animation(.easeInOut, value: barcodeProduct != nil)
    }
}
