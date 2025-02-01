//
//  TagStorageManager.swift
//  App
//
//  Created by 영준 이 on 1/29/25.
//

import Foundation

struct WordSet: Codable {
    let name: String
    let words: [String]
    let settings: Settings
    
    struct Settings: Codable {
        let replaceSpaces: Bool
        let attachSharp: Bool
        let generateCombinations: Bool
    }
}

class TagStorageManager {
    static let shared = TagStorageManager()
    private let defaults = UserDefaults.standard
    private var cachedWordSets: [WordSet]? = nil
    
    private let WORD_SETS_KEY = "wordSets"
    private let CURRENT_SET_KEY = "currentSetName"
    
    func saveWordSet(name: String, words: [String], settings: WordSet.Settings) {
        var wordSets = getAllWordSets()
        let newSet = WordSet(name: name, words: words, settings: settings)
        
        // Update or add the word set
        if let index = wordSets.firstIndex(where: { $0.name == name }) {
            wordSets[index] = newSet
        } else {
            wordSets.append(newSet)
        }
        
        if let encoded = try? JSONEncoder().encode(wordSets) {
            defaults.set(encoded, forKey: WORD_SETS_KEY)
            cachedWordSets = wordSets
        }
    }
    
    func getAllWordSets() -> [WordSet] {
        if let cachedWordSets {
            return cachedWordSets
        }
        
        guard let data = defaults.data(forKey: WORD_SETS_KEY),
              let storedWordSets = try? JSONDecoder().decode([WordSet].self, from: data) else {
            return []
        }
        
        cachedWordSets = storedWordSets
        
        return storedWordSets
    }
    
    func getWordSet(named name: String) -> WordSet? {
        return getAllWordSets().first { $0.name == name }
    }
    
    func deleteWordSet(named name: String) {
        var wordSets = getAllWordSets()
        wordSets.removeAll { $0.name == name }
        
        if let encoded = try? JSONEncoder().encode(wordSets) {
            defaults.set(encoded, forKey: WORD_SETS_KEY)
        }
    }
    
    func setCurrentSet(name: String) {
        defaults.set(name, forKey: CURRENT_SET_KEY)
    }
    
    func getCurrentSetName() -> String? {
        return defaults.string(forKey: CURRENT_SET_KEY)
    }
}
