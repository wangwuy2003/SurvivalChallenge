//
//  SurvivalChallengeAPI.swift
//  SurvivalChallenge
//
//  Created by Apple on 18/4/25.
//

import Foundation
internal import Alamofire

struct SurvivalChallengeAPI: APIClient {
    typealias Model = [SurvivalChallengeEntity]

    var environment: APIEnviroment {
        return SurvivalChallengeEnvironment()
    }

    var params: [String : Any] {
        return ["sign": "a7f3d9b2c5e8g1h6i4j0k7l3m9n2o5p8q1r6s4t0u"]
    }

    var path: String {
        return "/survival.challenge.filter.ios"
    }

    var header: [String : String] {
        return ["Content-Type": "application/json"]
    }

    var method: HTTPMethod {
        return .get
    }
}
