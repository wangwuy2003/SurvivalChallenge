//
//  SurvivalChallengeAPI.swift
//  SurvivalChallenge
//
//  Created by Apple on 18/4/25.
//

struct SurvivalChallengeEntity: Codable {
    let id: Int
    let name: String
    let category: String
    let imageUrl: [String]
    let imageUrlNew: [ImageUrlNew]
    let tab: String
    let level: Int
    let step: Int
    let mediatype: String
    let packageName: String
    let thumpUrl: String?
    let thumpFilter: String?
    let filterName: String
    let username: String
    let textDes: String
    let imgOptionUrl: [String]
    let imgResultUrl: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case imageUrl       = "image_url"
        case imageUrlNew    = "image_url_new"
        case tab
        case level
        case step
        case mediatype
        case packageName    = "package_name"
        case thumpUrl       = "thump_url"
        case thumpFilter    = "thump_filter"
        case filterName     = "filter_name"
        case username
        case textDes        = "text_des"
        case imgOptionUrl   = "img_option_url"
        case imgResultUrl   = "img_result_url"
    }
}

struct ImageUrlNew: Codable {
    let url: String
    let status: Int
    
    enum CodingKeys: CodingKey {
        case url
        case status
    }
}
