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
            case .defaultSearchFunction: return true
            case .addFoodToMeal: return true
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
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext

    @Model
    class RecentSearch {
        var query: String
        var date: Date
        
        init(query: String, date: Date) {
            self.query = query
            self.date = date
        }
    }
    
    @Query private var meals: [Meal]
    @Query private var recentSearches: [RecentSearch]

    enum SearchResult: Identifiable, Equatable {
        case recentSearch(String)
        case recentlyLoggedFood(ConsumedFood)
        case fdcFood(FdcSearchableFood)
        case fdcNutrient(Nutrient)
        case userMeal(UserMealsSearchableMeal)
        
        var id: String {
            switch self {
            case .recentSearch(let query): return query
            case .recentlyLoggedFood(let food): return "recentlyLoggedFood-\(food.fdcId)"
            case .fdcFood(let food): return "fdcFood-\(food.fdcId)"
            case .fdcNutrient(let nutrient): return "fdcNutrient-\(nutrient.fdcId)"
            case .userMeal(let meal): return "userMeal-\(meal.meal.id)"
            }
        }
        
        var isRecentSearch: Bool {
            switch self {
            case .recentSearch: return true
            default: return false
            }
        }
        
        var isRecentlyLoggedFood: Bool {
            switch self {
            case .recentlyLoggedFood: return true
            default: return false
            }
        }
        
        var isFdcFood: Bool {
            switch self {
            case .fdcFood: return true
            default: return false
            }
        }
        
        var isFdcNutrient: Bool {
            switch self {
            case .fdcNutrient: return true
            default: return false
            }
        }
        
        var isUserMeal: Bool {
            switch self {
            case .userMeal: return true
            default: return false
            }
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
    
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var analytics: NutrientLoggerAnalytics
    
    @Environment(\.isSearching) private var isSearching

    @StateObject private var reviewPrompter = ReviewPrompter()
    @State private var searchText: String = ""
    @State private var hasSearched: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var searchResults: [SearchResult] = []
    
    let searchFunction: SearchFunction
    let askForDateAndMealTime: Bool
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
                name: "Nutrients",
                symbol: "atom",
                results: searchResults.filter {
                    $0.isFdcNutrient && searchFunction.shouldIncludeFdcNutrients
                }
            ),
            .init(
                name: "Your Resuable Meals",
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
        fetchInitialSuggestions()
    }
    
    private func fetchInitialSuggestions() {
        if searchResults.isEmpty {
            if searchFunction.shouldIncludeRecentSearches {
                searchResults.append(contentsOf: fetchRecentSearches())
            }
            if searchFunction.shouldIncludeRecentlyLoggedFoods {
                searchResults.append(contentsOf: fetchRecentlyLoggedFoods())
            }
        }
    }
    
    private func fetchRecentSearches() -> [SearchResult] {
        recentSearches
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { SearchResult.recentSearch($0.query) }
    }
    
    private func fetchRecentlyLoggedFoods() -> [SearchResult] {
        do {
            var descriptor = FetchDescriptor<ConsumedFood>(
                sortBy: [ .init(\.created, order: .reverse) ]
            )
            descriptor.fetchLimit = 30
            
            return try modelContext.fetch(descriptor)
                .reduce(into: [:]) { dict, food in
                    if dict[food.fdcId]?.created ?? .distantPast < food.created {
                        dict[food.fdcId] = food
                    }
                }
                .map { $0.value }
                .sorted { $0.created > $1.created }
                .map(SearchResult.recentlyLoggedFood)
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
                if searchFunction.shouldIncludeFdcFoods {
                    group.addTask { await self.searchForRemoteFoods(searchText) }
                }
                if searchFunction.shouldIncludeUserMeals {
                    group.addTask { await self.searchUserMeals(searchText) }
                }
                if searchFunction.shouldIncludeFdcNutrients {
                    group.addTask { await self.searchRemoteNutrients(searchText) }
                }
                
                var results: [SearchResult] = []
                for await result in group {
                    results.append(contentsOf: result)
                }
                return results
            }
            
            if !searchResults.isEmpty {
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
    
    //TODO: Search for foods inside of meals too
    private func searchUserMeals(_ query: String) async -> [SearchResult] {
        let tokens = query.split(separator: " ")
        return meals
            .filter { $0.name.caseInsensitiveContainsAny(of: tokens) }
            .map { UserMealsSearchableMeal(meal: $0) }
            .map { SearchResult.userMeal($0) }
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
        onFoodSaved: @escaping (FoodItem, Portion) throws -> Void
    ) {
        self.searchFunction = searchFunction
        self.askForDateAndMealTime = askForDateAndMealTime
        self.onFoodSaved = onFoodSaved
    }
    
    var body: some View {
        List {
            AdRow()
            if searchResults.isEmpty && hasSearched && !isLoading {
                ContentUnavailableView(
                    "\"\(searchText)\"",
                    systemImage: "square.dashed",
                    description: Text("Nothing was found. Try searching for a different term.")
                )
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
        .animation(.snappy, value: searchText)
        .animation(.snappy, value: searchResults)
        .searchable(
            text: $searchText,
            prompt: Text("Foods, Meals, Nutrients...")
        )
        .onChange(of: searchText) { hasSearched = false }
        .onSubmit(of: .search) { doSearch() }
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
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Search")
                .bold()
        }
        ToolbarItem(placement: .topBarLeading) {
            BackButton()
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
    
    @ViewBuilder private func AdRow() -> some View {
        SimpleNativeAdView(size: .small)
            .listRowDefaultModifiers()
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
}

#Preview {
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }

    NavigationStack {
        FoodSearchView(onFoodSaved: FoodSaver.mock.saveFoodItem)
    }
}
