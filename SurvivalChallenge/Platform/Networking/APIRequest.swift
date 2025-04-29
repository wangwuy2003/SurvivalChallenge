//
//  Request.swift
//  BaseAFAPI
//
//  Created by ManhLD on 10/8/20.
//

import Foundation
internal import Alamofire

protocol APIRequest {
    var environment: APIEnviroment { get }
    var path: String { get }
    var encoding: ParameterEncoding { get }
    var method: HTTPMethod { get }
    var params: [String: Any] { get }
    var header: [String: String] { get }
    var request: URLRequest { get }
}

extension APIRequest {
    var fullUrl: URL {
        guard let url = URL(string: environment.baseUrl) else {
            fatalError("Invalid url")
        }
        guard !path.isEmpty else {
            return url
        }
        return url.appendingPathComponent(path)
    }
    
    var header: [String: String] {
        return environment.header
    }
    
    var params: [String: Any] {
        return [:]
    }
    
    var request: URLRequest {
        let originalRequest = try? URLRequest(url: fullUrl, method: method, headers: HTTPHeaders(header))
        
        guard let originReques = originalRequest else {
            return URLRequest(url: fullUrl)
        }
        switch method {
        case .put, .post:
            let encodedRequest = try? encoding.encode(originReques, with: params)
            
            guard var unwrappedUrlRequest = encodedRequest else {
                fatalError("Cannot encode request")
            }
            
            if let body = params.jsonData {
                unwrappedUrlRequest.httpBody = body
            }
            
            return unwrappedUrlRequest
        default:
            let encodedRequest = try? encoding.encode(originReques, with: params)
            
            guard let unwrappedUrlRequest = encodedRequest else {
                fatalError("Cannot encode request")
            }
            return unwrappedUrlRequest
        }
    }
    
    
    var encoding: ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    func printInfomationRequest() {
        print("Request :", request)
        
        do {
            
            if let data = request.httpBody,
                let json = try JSONSerialization.jsonObject(with: data,
                                                            options: []) as? [String: Any] {
                debugPrint(json)
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        print("Request full url :", fullUrl)
        print("Request method :", method)
        print("Request header :", header)
        print("Request params :", params)
    }
}
