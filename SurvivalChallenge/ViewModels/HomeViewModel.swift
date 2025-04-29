//
//  HomeViewModel.swift
//  SurvivalChallenge
//
//  Created by Apple on 18/4/25.
//
import Foundation

class HomeViewModel {
    static let shared = HomeViewModel()
    
    private let apiService: APIService
    var allChallenges: [SurvivalChallengeEntity] = []
    var filteredChallenges: [SurvivalChallengeEntity] = []
    private var selectedCategory: TopCategory = .hot {
        didSet {
            filterChallenges()
            onDataUpdated?()
        }
    }
    
    var audioItems: [SurvivalChallengeEntity] {
        return allChallenges.filter { $0.category.lowercased() == "audio" }
    }
    
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    var isLoading: Bool = false
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func fetchChallenges() {
        isLoading = true
        onDataUpdated?()
        
        Task {
            do {
                let challenges = try await apiService.fetchSurvivalChallengeFilters()
                allChallenges = challenges
                filterChallenges()
                isLoading = false
                onDataUpdated?()
            } catch {
                isLoading = false
                onError?(error)
                onDataUpdated?()
            }
        }
    }
    
    func selectCategory(_ category: TopCategory) {
        selectedCategory = category
    }

    var numberOfFilterItems: Int {
        filteredChallenges.count
    }
    
    var numberOfAllItems: Int {
        allChallenges.count
    }

    func challengeFilter(at index: Int) -> SurvivalChallengeEntity {
        filteredChallenges[index]
    }
    
    func challengeAll(at index: Int) -> SurvivalChallengeEntity {
        allChallenges[index]
    }

    private func filterChallenges() {
        switch selectedCategory {
        case .hot:
            filteredChallenges = allChallenges.prefix(13).map { $0 }
        case .ranking:
            filteredChallenges = allChallenges.filter { $0.category == "Ranking" }
        case .guess:
            filteredChallenges = allChallenges.filter { $0.category == "Guess" }
        case .coloring:
            filteredChallenges = allChallenges.filter { $0.category == "Coloring" }
        }
    }
    
    func getDesignType(for category: String, name: String) -> DesignType? {
        switch category.lowercased() {
        case "ranking":
            switch name {
            case "1":
                return .rankingType1
            case "2":
                return .rankingType2
            case "3":
                return .rankingType3
            case "4":
                return .rankingType2
            default:
                return nil
            }
        case "guess":
            return .guessType
        case "coloring":
            switch name {
            case "1":
                return .coloringType1
            case "2":
                return .coloringType2
            case "3":
                return .coloringType3
            case "4":
                return .coloringType4
            case "5":
                return .coloringType5
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
