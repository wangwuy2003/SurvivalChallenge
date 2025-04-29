//
//  Enviroment.swift
//  BaseAFAPI
//
//  Created by ManhLD on 10/8/20.
//

import Foundation

protocol APIEnviroment {
    var baseUrl: String { get }
    var timeout: TimeInterval { get }
    var header: [String: String] { get }
//    var apiKey: String { get }
}

struct DefaultEnvironment: APIEnviroment {
    var baseUrl: String {
        return "https://api.restful-api.dev"
    }

    var timeout: TimeInterval {
        return 30
    }

    var header: [String : String] {
        return [:]
    }
}

struct SurvivalChallengeEnvironment: APIEnviroment {
    var baseUrl: String {
        return Constants.apiEndpoint
    }

    var timeout: TimeInterval {
        return 30
    }

    var header: [String : String] {
        return ["Content-Type": "application/json"]
    }
}
