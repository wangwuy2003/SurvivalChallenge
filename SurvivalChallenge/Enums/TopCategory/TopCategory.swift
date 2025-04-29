//
//  TopCategory.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//
import Foundation

enum TopCategory: Int, CaseIterable, Codable {
    case hot
    case ranking
    case guess
    case coloring
    
    var displayTitle: String {
        switch self {
        case .hot:              return Localized.Home.hot
        case .ranking:          return Localized.Home.ranking
        case .guess:            return Localized.Home.guess
        case .coloring:         return Localized.Home.coloring
        }
    }
}
