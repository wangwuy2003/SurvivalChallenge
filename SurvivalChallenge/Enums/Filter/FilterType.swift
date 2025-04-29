//
//  RankingType.swift
//  SurvivalChallenge
//
//  Created by Apple on 21/4/25.
//

import Foundation

enum FilterType: String {
    case ranking    = "ranking"
    case guess      = "guess"
    case coloring   = "coloring"
    case none       = "none"
}

enum DesignType {
    case rankingType1
    case rankingType2
    case rankingType3
    case guessType
    case coloringType1
    case coloringType2
    case coloringType3
    case coloringType4
    case coloringType5
}

enum RankingCellStyle {
    case case1
    case case2
    case case3
}

let designToRankingMap: [DesignType: RankingCellStyle] = [
    .rankingType1: .case1,
    .rankingType2: .case2,
    .rankingType3: .case3
]
