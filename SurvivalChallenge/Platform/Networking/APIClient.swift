//
//  Networking.swift
//  BaseAFAPI
//
//  Created by ManhLD on 10/8/20.
//

import Foundation
internal import Alamofire

typealias APIClient = APIOperation & APIRequest


protocol APIOperation {
    associatedtype Model: Codable
    func execute() async throws -> APIResponse<Model>
    func executeModel() async throws -> Model
    func uploadFile(fileURL: URL, fileKey: String) async throws -> Model
}

extension APIOperation where Self: APIRequest {
    func execute() async throws -> APIResponse<Model> {
        self.printInfomationRequest()
        return try await AF.request(self.request).serializingDecodable(APIResponse<Model>.self).value
    }

    func executeModel() async throws -> Model {
        self.printInfomationRequest()
        return try await AF.request(self.request).serializingDecodable(Model.self).value
    }

    func uploadFile(fileURL: URL, fileKey: String) async throws -> Model {
        self.printInfomationRequest()
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { formData in
                formData.append(fileURL, withName: fileKey)

                for (key, value) in params {
                    if let value = value as? String {
                        formData.append(Data(value.utf8), withName: key)
                    }
                }
            }, to: request.url?.absoluteString ?? "", headers: HTTPHeaders(header))
            .validate()
            .responseDecodable(of: Model.self) { response in
                switch response.result {
                case .success(let decodedData):
                    continuation.resume(returning: decodedData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
