//
//  MTError.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

import Foundation

public protocol MTErrorProtocol: LocalizedError {
    var title: String? { get }
    var code: Int { get }
}

public struct MTError: MTErrorProtocol {
    public var title: String?
    public var code: Int
    public var errorDescription: String? { return _description }
    public var failureReason: String? { return _description }

    private var _description: String

    public init(title: String?, description: String, code: Int) {
        self.title = title ?? "Error"
        self._description = description
        self.code = code
    }
}
