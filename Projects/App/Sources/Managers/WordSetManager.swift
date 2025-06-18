//
//  WordSetManager.swift
//  App
//
//  Created by 영준 이 on 1/29/25.
//

import Foundation
import SwiftData

@MainActor
class WordSetManager {
    static let shared = WordSetManager()
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        do {
            modelContainer = try ModelContainer(for: WordSetModel.self)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    func loadWordSets() -> [WordSetModel] {
        (try? modelContext.fetch(FetchDescriptor<WordSetModel>())) ?? []
    }
    
    func createWordSet(name: String = "Default", words: [String], replaceSpaces: Bool, attachSharp: Bool, generateCombinations: Bool) -> WordSetModel {
        let newSet = WordSetModel(name: name, words: words.map{ WordModel(text: $0) },
                                replaceSpaces: replaceSpaces,
                                attachSharp: attachSharp,
                                generateCombinations: generateCombinations)
        modelContext.insert(newSet)
        
        try? modelContext.save()
        
        return newSet
    }
    
    func deleteWord(set: WordSetModel) {
        modelContext.delete(set)
        
        self.save()
    }
    
    func deleteWord(_ word: WordModel) {
        modelContext.delete(word)
        self.save()
    }
    
    func save() {
        try? modelContext.save()
    }
}
