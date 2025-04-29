//
//  APIError.swift
//  BaseAFAPI
//
//  Created by ManhLD on 10/8/20.
//

import Foundation

struct APIError {
    
    static let defaultErrorCode              = 9999
    static let parsingDataErrorCode          = 6666
    static let invalidSSL                    = -1202
    static let noInternetConnection          = -1009
    static let unauthorized                  = "Unauthorized"
    static let parseDataError                = "Parse Data Error"
    static let internalServerError           = "Internal Server Error"
    static let serviceTemporarilyUnavailable = "Service Temporarily Unavailable"
    static let defaultError                  = "Something went worng, please check your connection"
    static let forbiden                      = "Forbidden error"
    static let notFound                      = "Not found"
    static let somethingWrong                = "Something went worng"
    
    static func error(_ statusCode: Int?) -> Error {
        let _statusCode = statusCode ?? defaultErrorCode
        switch statusCode {
        case 6666:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.parseDataError)
        case 401:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.unauthorized)
        case 403:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.forbiden)
        case 404:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.notFound)
        case 500:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.internalServerError)
        case 503:
            return errorForStatusCode(statusCode: _statusCode, errorDescription: self.serviceTemporarilyUnavailable)
        default:
            return errorForStatusCode(statusCode: self.defaultErrorCode, errorDescription: self.defaultError)
        }
    }
    
    static func errorForStatusCode(statusCode: Int, errorDescription: String) -> Error {
        return NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
    }
}
