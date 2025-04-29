//
//  CryptoSwiftExt.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS) && canImport(CryptoSwift)
import UIKit
import CryptoSwift

public extension String {
    func aesEncrypt(key: String, iv: String) -> String? {
        guard let data = self.data(using: .utf8) else {return nil}
        guard let encrypted = try? AES(key: key, iv: iv, padding: .pkcs7).encrypt([UInt8](data)) else {return nil}
        
        return Data(encrypted).base64EncodedString()
    }

    func aesDecrypt(key: String, iv: String) -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        guard let decrypted = try? AES(key: key, iv: iv, padding: .pkcs7).decrypt([UInt8](data)) else {return nil}
        
        return String(bytes: decrypted, encoding: .utf8) ?? self
    }
}

#endif
