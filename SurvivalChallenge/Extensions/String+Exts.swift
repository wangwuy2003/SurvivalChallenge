//
//  String+Exts.swift
//  AINoteTaker
//
//  Created by Luong Manh on 11/3/25.
//

import Foundation

extension String {
    func clipped(maxCharacters: Int) -> String {
        String(prefix(maxCharacters))
    }
    
    func replaceSpacesWithUnderscores() -> String {
        self.replacingOccurrences(of: " ", with: "_")
    }

    var localized: String {
        let localizedText = NSLocalizedString(self, bundle: Bundle.main, comment: "")
        return localizedText.isEmpty ? self : localizedText
    }
}
