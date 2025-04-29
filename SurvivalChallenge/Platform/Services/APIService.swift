//
//  Untitled.swift
//  SurvivalChallenge
//
//  Created by Apple on 18/4/25.
//
import Foundation

class APIService {
    let request = SurvivalChallengeAPI()

    func fetchSurvivalChallengeFilters() async throws -> [SurvivalChallengeEntity] {
        do {
            let response = try await request.execute()
            print("Full API Response:", response)
            print("Data items:", response.data ?? "nil")
            guard let filters = response.data else {
                print("No data in response")
                throw APIError.error(nil)
            }
            return filters
        } catch {
            print("API Error:", error)
            throw APIError.error(error._code)
        }
    }
}
