//
//  TagStorageManager.swift
//  App
//
//  Created by 영준 이 on 1/29/25.
//

// TagStorageManager.swift
import Foundation

class TagStorageManager {
    static let shared = TagStorageManager()
    private let defaults = UserDefaults.standard
    
    private let WORDS_KEY = "savedWords"
    private let REPLACE_SPACES_KEY = "replaceSpaces"
    private let ATTACH_SHARP_KEY = "attachSharp"
    private let GENERATE_COMBINATIONS_KEY = "generateCombinations"
    
    private init() {}
    
    func saveWords(_ words: [String]) {
        defaults.set(words, forKey: WORDS_KEY)
    }
    
    func loadWords() -> [String] {
        return defaults.stringArray(forKey: WORDS_KEY) ?? []
    }
    
    func saveSettings(replaceSpaces: Bool, attachSharp: Bool, generateCombinations: Bool) {
        defaults.set(replaceSpaces, forKey: REPLACE_SPACES_KEY)
        defaults.set(attachSharp, forKey: ATTACH_SHARP_KEY)
        defaults.set(generateCombinations, forKey: GENERATE_COMBINATIONS_KEY)
    }
    
    func loadSettings() -> (replaceSpaces: Bool, attachSharp: Bool, generateCombinations: Bool) {
        let replaceSpaces = defaults.bool(forKey: REPLACE_SPACES_KEY)
        let attachSharp = defaults.bool(forKey: ATTACH_SHARP_KEY)
        let generateCombinations = defaults.bool(forKey: GENERATE_COMBINATIONS_KEY)
        return (replaceSpaces, attachSharp, generateCombinations)
    }
}
