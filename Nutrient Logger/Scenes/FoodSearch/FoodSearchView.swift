//
//  FoodSearchView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/9/25.
//

import SwiftUI
import SwinjectAutoregistration

//TODO: Add suggestions (recent searches, recently logged, etc)
//TODO: MVP: Save/load recent searches
//TODO: MVP: Make sure recently logged foods are getting fetched
//TODO: MVP: Make sure ContentUnavailableView is shown at appopriate times
struct FoodSearchView: View {
    
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
    
    struct SearchResultsSection: Identifiable {
        var id: UUID
        let name: String
        let symbol: String
        let results: [SearchResult]
        
        init(name: String, symbol: String, results: [SearchResult]) {
            self.id = UUID()
            self.name = name
            self.symbol = symbol
            self.results = results
        }
    }
    
    private let localDatabase = swinjectContainer~>LocalDatabase.self
    private let remoteDatabase = swinjectContainer~>RemoteDatabase.self
    private let userMealsDatabase = swinjectContainer~>UserMealsDatabase.self
    private let analytics = swinjectContainer~>NutrientLoggerAnalytics.self
    
    @Environment(\.isSearching) private var isSearching

    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    
    @State private var searchResults: [SearchResult] = []
    
    private var groupedSearchResults: [SearchResultsSection] {
        [
            .init(name: "Recent Searches", symbol: "magnifyingglass", results: searchResults.filter { $0.isRecentSearch }),
            .init(name: "Recently Logged", symbol: "arrow.clockwise.circle", results: searchResults.filter { $0.isRecentlyLoggedFood }),
            .init(name: "Nutrients", symbol: "atom", results: searchResults.filter { $0.isFdcNutrient }),
            .init(name: "Your Resuable Meals", symbol: "frying.pan", results: searchResults.filter { $0.isUserMeal }),
            .init(name: "Foods", symbol: "carrot", results: searchResults.filter { $0.isFdcFood }),
        ]
    }
    
    private func doSearch() {
        guard !searchText.isEmpty else { return }

        analytics.foodSearched(searchText)
        
        searchResults = []
        isLoading = true
        Task {
            searchResults = await withTaskGroup(of: Array<SearchResult>.self) { group in
                group.addTask { await self.searchForRemoteFoods(searchText) }
                group.addTask { await self.searchUserMeals(searchText) }
                group.addTask { await self.searchRemoteNutrients(searchText) }
                
                var results: [SearchResult] = []
                for await result in group {
                    results.append(contentsOf: result)
                }
                return results
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
    
    private func fetchRecentlyLoggedFoods() -> [SearchResult] {
        do {
            let foods = try localDatabase.getRecentlyLoggedFoods(50)
            return foods.map { SearchResult.recentlyLoggedFood($0) }
        } catch {
            print("Error loading recent foods: \(error.localizedDescription)")
        }
        return []
    }
    
    var body: some View {
        List {
            if searchResults.isEmpty && !isSearching && !isLoading {
                ContentUnavailableView(
                    "No Results",
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
        .onSubmit(of: .search) { doSearch() }
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
            FoodDetailsView(foodId: food.fdcId, mode: .searchResult)
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
            FoodDetailsView(foodId: food.fdcId, mode: .searchResult)
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
        FoodSearchView()
    }
}
