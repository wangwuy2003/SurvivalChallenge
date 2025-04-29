//
//  APIRespone.swift
//  SwiftiOS_Base
//
//  Created by Luong Manh on 19/04/2024.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
    var status: Int?
    var totalResults: Int?
    var data: T?
    var message: String?
}
