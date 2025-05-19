//
//  Localized.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//

import Foundation

enum Localized {
    enum Intro {
        static let intro1 = "intro1".localized
        static let intro2 = "intro2".localized
        static let intro3 = "intro3".localized
    }
    
    enum Tabbar {
        static let home = "home".localized
        static let myVideos = "myVideos".localized
    }
    
    enum Home {
        static let survivalChallenge = "survivalChallenge".localized
        static let hot = "hot".localized
        static let ranking = "ranking".localized
        static let guess = "guess".localized
        static let coloring = "coloring".localized
    }
    
    enum Setting {
        static let setting = "setting".localized
        static let language = "language".localized
        static let privacyPolicy = "privacyPolicy".localized
        static let termOfUse = "termOfUse".localized
    }
    
    enum MyVideos {
        static let myVideos = "myVideos".localized
        static let share = "share".localized
        static let delete = "delete".localized
        static let deleteYourVideo = "deleteYourVideo".localized
        static let cancel = "cancel".localized
        static let emptyFolder = "emptyFolder".localized
    }
    
    enum Video {
        static let save = "save".localized
    }
    
    enum Camera {
        static let addMusic = "addMusic".localized
        static let progressReachedTheLimit = "progressReachedTheLimit".localized
        static let discardYourVideo = "discardYourVideo".localized
        static let discardTheLastClip = "discardTheLastClip".localized
        static let cancel = "cancel".localized
        static let discard = "discard".localized
    }
    
    enum DescriptionChallenge {
        static let tryNow = "tryNow".localized
    }
    
    enum Result {
        static let share = "share".localized
        static let save = "save".localized
        static let discardYourVideo = "discardYourVideo".localized
        static let cancel = "cancel".localized
        static let discard = "discard".localized
        static let success = "success".localized
        static let videoSavedSuccessfully = "videoSavedSuccessfully".localized
        static let ok = "ok".localized
        static let error = "error".localized
        static let videoSavedError = "videoSavedError".localized
    }
}
