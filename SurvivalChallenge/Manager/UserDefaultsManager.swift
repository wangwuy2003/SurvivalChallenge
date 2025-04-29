

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {
    }
    private struct Keys {
        static let username = "UsernameKey"
        static let isFirstOpenDuoPage = "IsFirstOpenDuoPageKey"
        static let isFirstOpenSinglePage = "IsFirstOpenSinglePageKey"
        static let isFirstOpenApp = "IsFirstOpenAppKey"
        static let language = "LanguageKey"
        static let isFirstOpenIntroPage = "IsFirstOpenIntroPage"
        static let countShowInterAds = "CountShowInterAds"
        static let adsEnabled = "AdsEnabled"
        static let countImage = "CountImage"
        static let isShowInter = "IsShowInter"
        static let isFirtsPermission = "IsFirtsPermission"
        static let isRatingStar = "IsRatingStar"
        static let isRequestRate = "IsRequestRate"
        static let countPicture = "countPicture"
        static let isOpenSettingPermissonNetwork = "isOpenSettingPermissonNetwork"
        static let isRequestNoti = "isRequestNoti"
        static let isReloadBannerColapse = "isReloadBannerColapse"
        static let countInter = "countInter"
        static let isFirstOpenCMP = "isFirstOpenCMP"
        static let onResumeCanLoad = "onResumeCanLoad"
        static let countFiveStar = "countFiveStar"
        static let isRequestPhoto = "isRequestPhoto"
        static let nameLanguage = "nameLanguage"
        static let ratingIsOn = "ratingIsOn"
        static let goToSetting = "goToSetting"
        static let selectedFlag = "selectedFlag"
        static let goToMail = "goToMail"
        static let trendingModels = "trendingModels"
        static let agreeTerm = "agreeTerm"
        static let countRate = "countRate"
        
        //IAP
        static let isRemoveAllAds = "isRemoveAllAds"
        static let subscriptionDuration = "SubscriptionDuration"
        static let subscriptionDurationTrial = "subscriptionDurationTrial"
        static let purchaseDateTrial = "purchaseDateTrial"
        static let purchaseDate = "PurchaseDate"
        
        
        //Remote Config
        static let isTimeInter = "isTimeInter"
        static let time_inter = "time_inter"
        static let isShowATT = "isShowATT"
        
        //settings
        static let firstRequestBiometric = "firstRequestBiometric"
        static let syncCloud = "syncCloud"
        static let usingFaceId = "usingFaceId"
        static let guideAutoFill_1 = "guideAutoFill_1"
        static let guideAutoFill_2 = "guideAutoFill_2"
        static let first_splash = "first_splash"
        static let firstMenu = "firstMenu"
        static let firstGuide = "firstGuide"
        static let firstAutoFill = "firstAutoFill"
        
    }
    
    private let languages: [Languages] = [
        Languages(language: Language.english, code: true),
        Languages(language: Language.spanish, code: false),
        Languages(language: Language.french, code: false),
        Languages(language: Language.arabic, code: false),
        Languages(language: Language.hindi, code: false),
        Languages(language: Language.bengali, code: false),
        Languages(language: Language.rusian, code: false),
        Languages(language: Language.portuguese, code: false),
        Languages(language: Language.indonesian, code: false),
        Languages(language: Language.german, code: false),
        Languages(language: Language.italian, code: false),
        Languages(language: Language.korean, code: false),
    ]
    
    var firstAutoFill: Bool {
        get {
            return defaults.bool(forKey: Keys.firstAutoFill)
        }
        set {
            defaults.set(newValue, forKey: Keys.firstAutoFill)
        }
    }
    
    var firstGuide: Bool {
        get {
            return defaults.bool(forKey: Keys.firstGuide)
        }
        set {
            defaults.set(newValue, forKey: Keys.firstGuide)
        }
    }
    
    var firstMenu: Bool {
        get {
            return defaults.bool(forKey: Keys.firstMenu)
        }
        set {
            defaults.set(newValue, forKey: Keys.firstMenu)
        }
    }

    
    var first_splash: Bool {
        get {
            return defaults.bool(forKey: Keys.first_splash)
        }
        set {
            defaults.set(newValue, forKey: Keys.first_splash)
        }
    }
    
    var guideAutoFill_2: Bool {
        get {
            return defaults.bool(forKey: Keys.guideAutoFill_2)
        }
        set {
            defaults.set(newValue, forKey: Keys.guideAutoFill_2)
        }
    }
    
    var guideAutoFill_1: Bool {
        get {
            return defaults.bool(forKey: Keys.guideAutoFill_1)
        }
        set {
            defaults.set(newValue, forKey: Keys.guideAutoFill_1)
        }
    }
    
    var usingFaceId: Bool {
        get {
            return defaults.bool(forKey: Keys.usingFaceId)
        }
        set {
            defaults.set(newValue, forKey: Keys.usingFaceId)
        }
    }
    
    var firstRequestBiometric: Bool {
        get {
            return defaults.bool(forKey: Keys.firstRequestBiometric)
        }
        set {
            defaults.set(newValue, forKey: Keys.firstRequestBiometric)
        }
    }
    
    var syncCloud: Bool {
        get {
            return defaults.bool(forKey: Keys.syncCloud)
        }
        set {
            defaults.set(newValue, forKey: Keys.syncCloud)
        }
    }
    
    var countRate: Int {
        get {
            return defaults.integer(forKey: Keys.countRate)
        }
        set {
            defaults.set(newValue, forKey: Keys.countRate)
        }
    }
    
    
    var agreeTerm: Bool {
        get {
            return defaults.bool(forKey: Keys.agreeTerm)
        }
        set {
            defaults.set(newValue, forKey: Keys.agreeTerm)
        }
    }
    
    var goToMail: Bool {
        get {
            return defaults.bool(forKey: Keys.goToMail)
        }
        set {
            defaults.set(newValue, forKey: Keys.goToMail)
        }
    }
    
    var goToSetting: Bool {
        get {
            return defaults.bool(forKey: Keys.goToSetting)
        }
        set {
            defaults.set(newValue, forKey: Keys.goToSetting)
        }
    }
    
    
    
    var subscriptionDuration: Int {
        get {
            return defaults.integer(forKey: Keys.subscriptionDuration)
        }
        set {
            defaults.set(newValue, forKey: Keys.subscriptionDuration)
        }
    }
    
    var subscriptionDurationTrial: Int {
        get {
            return defaults.integer(forKey: Keys.subscriptionDurationTrial)
        }
        set {
            defaults.set(newValue, forKey: Keys.subscriptionDurationTrial)
        }
    }
    
    var purchaseDateTrial: Date? {
        get {
            return defaults.object(forKey: Keys.purchaseDateTrial) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.purchaseDateTrial)
        }
    }
    
    var purchaseDate: Date? {
        get {
            return defaults.object(forKey: Keys.purchaseDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.purchaseDate)
        }
    }
    
    var isShowATT: Bool {
        get {
            return defaults.bool(forKey: Keys.isShowATT)
        }
        set {
            defaults.set(newValue, forKey: Keys.isShowATT)
        }
    }
    
    var time_inter: Int {
        get {
            return defaults.integer(forKey: Keys.time_inter)
        }
        set {
            defaults.set(newValue, forKey: Keys.time_inter)
        }
    }
    
    var isTimeInter: Date? {
        get {
            return defaults.object(forKey: Keys.isTimeInter) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.isTimeInter)
        }
    }
    
    var countFiveStar: Int {
        get {
            return defaults.integer(forKey: Keys.countFiveStar)
        }
        set {
            defaults.set(newValue, forKey: Keys.countFiveStar)
        }
    }
    
    var isRatingStar: Bool {
        get {
            return defaults.bool(forKey: Keys.isRatingStar)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRatingStar)
        }
    }
    
    var isRequestRate: Bool {
        get {
            return defaults.bool(forKey: Keys.isRequestRate)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRequestRate)
        }
    }
    
    var isFirstOpenCMP: Bool {
        get {
            return defaults.bool(forKey: Keys.isFirstOpenCMP, defaultValue: false)
        }
        set {
            defaults.set(newValue, forKey: Keys.isFirstOpenCMP)
        }
    }
    
    
    var isRemoveAllAds: Bool {
        get {
            return defaults.bool(forKey: Keys.isRemoveAllAds)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRemoveAllAds)
        }
    }
    
    var isRequestPhoto: Bool {
        get {
            return defaults.bool(forKey: Keys.isRequestPhoto)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRequestPhoto)
        }
    }
    
    var selectedFlag: Int {
        get {
            return defaults.integer(forKey: Keys.selectedFlag)
        }
        set {
            defaults.set(newValue, forKey: Keys.selectedFlag)
        }
    }
    
    var onResumeCanLoad: Bool {
        get {
            return defaults.bool(forKey: Keys.onResumeCanLoad)
        }
        set {
            defaults.set(newValue, forKey: Keys.onResumeCanLoad)
        }
    }
    
    var isRequestNoti: Bool {
        get {
            return defaults.bool(forKey: Keys.isRequestNoti)
        }
        set {
            defaults.set(newValue, forKey: Keys.isRequestNoti)
        }
    }
    
    var isShowInter: Bool {
        get {
            return defaults.bool(forKey: Keys.isShowInter)
        }
        set {
            defaults.set(newValue, forKey: Keys.isShowInter)
        }
    }
    
    var isReloadBannerColapse: Bool {
        get {
            return defaults.bool(forKey: Keys.isReloadBannerColapse)
        }
        set {
            defaults.set(newValue, forKey: Keys.isReloadBannerColapse)
        }
    }
    
    
    var username: String {
        get {
            return defaults.string(forKey: Keys.username, defaultValue: "")
        }
        set {
            defaults.set(newValue, forKey: Keys.username)
        }
    }
    
    
    var nameLanguage: String {
        get {
            return defaults.string(forKey: Keys.nameLanguage, defaultValue: "English")
        }
        set {
            defaults.set(newValue, forKey: Keys.nameLanguage)
        }
    }
    
    var isFirstOpenApp: Bool {
        get {
            return defaults.bool(forKey: Keys.isFirstOpenApp)
        }
        set {
            defaults.set(newValue, forKey: Keys.isFirstOpenApp)
        }
    }
    
    
    func encodeArrayToData<T: Codable>(_ array: [T]) -> Data? {
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(array)
        } catch {
            print("Error encoding array to data: \(error)")
            return nil
        }
    }
    
    func saveArrayToUserDefaults<T: Codable>(_ array: [T], forKey key: String) {
        guard let data = encodeArrayToData(array) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func retrieveArrayFromUserDefaults<T: Codable>(forKey key: String) -> [T]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([T].self, from: data)
        } catch {
            print("Error decoding data to array: \(error)")
            return nil
        }
    }
    
    func firstSaveLanguages() {
        saveArrayToUserDefaults(languages, forKey: Keys.language)
    }
    
    func saveLanguage(listLanguages: [Languages]) {
        saveArrayToUserDefaults(listLanguages, forKey: Keys.language)
    }
    
    func setLanguageDefaults() -> (Language,Int) {
        if let retrievedLanguages: [Languages] = retrieveArrayFromUserDefaults(forKey: Keys.language) {
            for (idx,language) in retrievedLanguages.enumerated() {
                if language.code {
                    return (language.language,idx)
                }
            }
        }
        return (.english,0)
    }
    
    func getLanguage() -> [Languages]{
        if let retrievedLanguages: [Languages] = retrieveArrayFromUserDefaults(forKey: Keys.language) {
            return retrievedLanguages
        }
        return []
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if let value = self.value(forKey: key) as? Bool {
            return value
        }
        return defaultValue
    }
    
    func string(forKey key: String, defaultValue: String) -> String {
        if let value = self.value(forKey: key) as? String {
            return value
        }
        return defaultValue
    }
    func setStringArray(_ value: [String], forKey key: String) {
        self.set(value, forKey: key)
    }

    func getStringArray(forKey key: String) -> [String]? {
        return self.value(forKey: key) as? [String]
    }
}


