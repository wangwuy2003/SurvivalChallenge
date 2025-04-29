//
//  LanguageViewModel.swift
//  Remote All Bazooka
//
//  Created by Bot on 27/03/2024.
//


import Foundation

class LanguageViewModel: NSObject {
    
    var listLanguage: [Languages] = []
    
    override init() {
        super.init()
        self.listLanguage = UserDefaultsManager.shared.getLanguage()
    }
    
    func selectedLanguage(selectedFlag: inout Int, firstSelected: inout Int, isSplash: Bool) {
        for (idx,item) in listLanguage.enumerated() {
            if item.code {
                if !isSplash {
                    selectedFlag = idx
                }
                firstSelected = idx
            }
        }
    }
    
    func getCountLanguage() -> Int {
        return listLanguage.count
    }
    
    func getName(index: Int) -> String {
        return listLanguage[index].language.name
    }
    
    func changeLanguage(selectedFlag: Int, firstSelected: Int) {
        listLanguage[selectedFlag].code = true
        if firstSelected >= 0 {
            listLanguage[firstSelected].code = false
        }
        UserDefaultsManager.shared.nameLanguage = listLanguage[selectedFlag].language.name
        UserDefaultsManager.shared.saveLanguage(listLanguages: listLanguage)
        Bundle.set(language: listLanguage[selectedFlag].language)
    }
}

