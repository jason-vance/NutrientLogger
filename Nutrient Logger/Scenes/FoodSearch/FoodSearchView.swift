//
//  FoodSearchView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import SwiftUI
import SwiftData
import SwinjectAutoregistration

//TODO: Auto focus search bar
struct FoodSearchView: View {
    
    enum SearchFunction {
        case defaultSearchFunction
        case addFoodToMeal
        
        var shouldIncludeRecentSearches: Bool {
            switch self {
            case .defaultSearchFunction: return true
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
    }
    
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
    
    @Query private var recentSearches: [RecentSearch]

    enum SearchResult: Identifiable, Equatable {
        case recentSearch(String)
        case recentlyLoggedFood(FoodItem)
        case fdcFood(FdcSearchableFood)
        case fdcNutrient(Nutrient)
        case userMeal(UserMealsSearchableMeal)
        
        var id: String {
            switch self {
            case .recentSearch(let query): return query
            case .recentlyLoggedFood(let food): return "recentlyLoggedFood-\(food.fdcId)"
            case .fdcFood(let food): return "fdcFood-\(food.fdcId)"
            case .fdcNutrient(let nutrient): return "fdcNutrient-\(nutrient.fdcId)"
            case .userMeal(let meal): return "userMeal-\(meal.mealId)"
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
    
    
    @Inject private var localDatabase: LocalDatabase
    @Inject private var remoteDatabase: RemoteDatabase
    @Inject private var userMealsDatabase: UserMealsDatabase
    @Inject private var analytics: NutrientLoggerAnalytics
    
    @Environment(\.isSearching) private var isSearching

    @State private var searchText: String = ""
    @State private var hasSearched: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var searchResults: [SearchResult] = []
    
    let searchFunction: SearchFunction
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
            return try localDatabase.getRecentlyLoggedFoods(30)
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
        
        Task {
            await self.promptForReview()
        }
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
        do {
            return try userMealsDatabase
                .search(query)
                .map { SearchResult.userMeal($0) }
        } catch {
            print("Could not complete meal search: \(error.localizedDescription)")
        }
        return []
    }
    
    //TODO: MVP: Uncomment this when ready for review prompting
    private func promptForReview() async {
        if (await shouldPromptForReview()) {
//            let prompt = ReviewPrompter(screen: self as! UIViewController)
//            prompt.promptUserForReview(areYouEnjoyingPrompt: "Are you enjoying Nutrient Logger?")
        }
    }

    private func shouldPromptForReview() async -> Bool {
        return await Task.init(priority: .userInitiated) {
            do {
                guard let earliestFood = try localDatabase.getEarliestFood()
                else {
                    return false
                }
                guard let mostRecentFood = try localDatabase.getMostRecentFood()
                else {
                    return false
                }

                let timeDiff = abs(mostRecentFood.created.distance(to: earliestFood.created))
                let fiveDays = TimeInterval.fromDays(0.5)
                return timeDiff > fiveDays
            } catch {
                print("Error checking least and most recently logged food items: \(error.localizedDescription)")
                return false
            }
        }.value
    }
    
    init(
        searchFunction: SearchFunction = .defaultSearchFunction,
        onFoodSaved: @escaping (FoodItem, Portion) throws -> Void
    ) {
        self.searchFunction = searchFunction
        self.onFoodSaved = onFoodSaved
    }
    
    var body: some View {
        List {
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
    }
    
    @ToolbarContentBuilder private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Search")
                .bold()
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
    
    @ViewBuilder private func RecentlyLoggedFoodRow(_ food: FoodItem) -> some View {
        NavigationLink {
            FoodDetailsView(
                foodId: food.fdcId,
                mode: .searchResult,
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
                foodId: food.fdcId,
                mode: .searchResult,
                onFoodSaved: onFoodSaved
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
            //TODO: MVP: Navigate to NutrientDetailsView
            Text("Nutrient Details")
//            NutrientDetailsView(nutrientId: nutrient.fdcId)
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
            //TODO: MVP: Navigate to MealDetailsView
            Text("Meal Details")
//            MealDetailsView(mealId: meal.mealId)
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
    let _ = swinjectContainer.autoregister(LocalDatabase.self) { LocalDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(RemoteDatabase.self) { RemoteDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(UserMealsDatabase.self) { UserMealsDatabaseForScreenshots() }
    let _ = swinjectContainer.autoregister(NutrientLoggerAnalytics.self) { MockNutrientLoggerAnalytics() }

    NavigationStack {
        FoodSearchView(onFoodSaved: FoodSaver.mock.saveFoodItem)
    }
}
