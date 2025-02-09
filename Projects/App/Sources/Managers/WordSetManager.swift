//
//  WordSetManager.swift
//  App
//
//  Created by 영준 이 on 1/29/25.
//

import Foundation
import SwiftData

@MainActor
class WordSetManager : ObservableObject {
    static let shared = WordSetManager()
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    @Published var currentSet: WordSetModel!
    @Published var wordSets: [WordSetModel] = []
    
    private init() {
        do {
            modelContainer = try ModelContainer(for: WordSetModel.self)
            modelContext = modelContainer.mainContext
            loadWordSets()
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    func loadWordSets() {
        wordSets = (try? modelContext.fetch(FetchDescriptor<WordSetModel>())) ?? []
    }
    
    func saveWordSet(name: String, words: [String], replaceSpaces: Bool, attachSharp: Bool, generateCombinations: Bool) {
        if let existing = try? modelContext.fetch(FetchDescriptor<WordSetModel>(predicate: #Predicate<WordSetModel> { $0.name == name })).first {
            existing.words = words
            existing.replaceSpaces = replaceSpaces
            existing.attachSharp = attachSharp
            existing.generateCombinations = generateCombinations
        } else {
            let newSet = WordSetModel(name: name, words: words,
                                    replaceSpaces: replaceSpaces,
                                    attachSharp: attachSharp,
                                    generateCombinations: generateCombinations)
            modelContext.insert(newSet)
        }
        
        try? modelContext.save()
        loadWordSets()
    }
    
    func getAllWordSets() -> [WordSetModel] {
        return wordSets
    }
    
    func getWordSet(named name: String) -> WordSetModel? {
        return try? modelContext.fetch(FetchDescriptor<WordSetModel>(
            predicate: #Predicate<WordSetModel> { $0.name == name }
        )).first
    }
    
    func deleteWordSet(named name: String) {
        if let set = getWordSet(named: name) {
            modelContext.delete(set)
            try? modelContext.save()
            loadWordSets()
        }
    }
}