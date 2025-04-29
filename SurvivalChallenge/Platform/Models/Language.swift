

import Foundation
enum Language: Codable ,Equatable {
    case english
    case hindi
    case spanish
    case french
    case arabic
    case rusian
    case portuguese
    case indonesian
    case german
    case italian
    case korean
    case bengali
}

extension Language {

    var code: String {
        switch self {
        case .english:              return "en"
        case .hindi:                return "hi"
        case .spanish:              return "es"
        case .french:               return "fr"
        case .arabic:               return "ar"
        case .rusian:               return "ru"
        case .portuguese:           return "pt-PT"
        case .indonesian:           return "id"
        case .german:               return "de"
        case .italian:              return "it"
        case .korean:               return "ko"
        case .bengali:              return "bn-BD"
        }
    }

    var name: String {
        switch self {
//        case .english:              return "English (Default)"
//        case .korean:               return "Korean (한국인)"
//        case .hindi:                return "Hindi (भारतीय भाषा)"
//        case .spanish:              return "Spanish (Español)"
//        case .french:               return "French (Français)"
//        case .arabic:               return "Arabic (عربي)"
//        case .rusian:               return "Rusian (Pусский)"
//        case .portuguese:           return "Portuguese (Português)"
//        case .indonesian:           return "Indonesian (bahasa Indonesia)"
//        case .german:               return "German (Deutsch)"
//        case .italian:              return "Italian (Italiano)"
        case .english:              return "English"
        case .korean:               return "Korean"
        case .hindi:                return "Hindi"
        case .spanish:              return "Spanish"
        case .french:               return "French"
        case .arabic:               return "Arabic"
        case .rusian:               return "Russian"
        case .portuguese:           return "Portuguese"
        case .indonesian:           return "Indonesian"
        case .german:               return "German"
        case .italian:              return "Italian"
        case .bengali:               return "Bengali"
        }
    }
    
    var lg: String {
        switch self {
        case .english:              return "Language"
        case .korean:               return "언어"
        case .hindi:                return "भाषा"
        case .spanish:              return "Idioma"
        case .french:               return "Langue"
        case .arabic:               return "اللغة"
        case .rusian:               return "Язык"
        case .portuguese:           return "Idioma"
        case .indonesian:           return "Bahasa"
        case .german:               return "Sprache"
        case .italian:              return "Lingua"
        case .bengali:              return "ভাষা"
        }
    }
}

extension Language {

    init?(languageCode: String?) {
        guard let languageCode = languageCode else { return nil }
        switch languageCode {
        case "en":              self = .english
        case "hi":              self = .hindi
        case "es":              self = .spanish
        case "fr":              self = .french
        case "ar":              self = .arabic
        case "ko":              self = .korean
        case "ru":              self = .rusian
        case "pt-PT":           self = .portuguese
        case "id":              self = .indonesian
        case "it":              self = .italian
        case "de":              self = .german
        case "bn-BD":           self = .bengali
        default:                return nil
        }
    }
}
