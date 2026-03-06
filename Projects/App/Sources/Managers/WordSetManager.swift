//
//  WordSetManager.swift
//  App
//
//  Created by 영준 이 on 1/29/25.
//

import Foundation
import SwiftData
import Combine
import CoreData

@MainActor
class WordSetManager {
    static let shared = WordSetManager()
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        do {
            let config: ModelConfiguration = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.toyboy2.tagforge"))
            modelContainer = try ModelContainer(for: WordSetModel.self, WordModel.self, configurations: config)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    // CloudKit import event publisher — fires when the initial iCloud import finishes
    // (regardless of whether data was found), which is the earliest safe moment to create defaults.
    var cloudKitEventPublisher: AnyPublisher<NSPersistentCloudKitContainer.Event, Never> {
        NSPersistentCloudKitContainer.eventChangedPublisher
    }

    // NSManagedObjectContextDidSave Notification Publisher
    var remoteChangePublisher: AnyPublisher<Notification, Never> {
//        guard let nsContext = (modelContext as? NSObject)?.value(forKey: "context") as? NSManagedObjectContext else {
//            // fallback: never emit
//            return Empty().eraseToAnyPublisher()
//        }
        
        return NotificationCenter.default
            .publisher(for: NSNotification.Name.NSPersistentStoreRemoteChange)
            .eraseToAnyPublisher()
    }
    
    func loadWordSets() -> [WordSetModel] {
        (try? modelContext.fetch(FetchDescriptor<WordSetModel>())) ?? []
    }
    
    func createWordSet(name: String = "Default", words: [String], attachSharp: Bool, generateCombinations: Bool) -> WordSetModel {
        let newSet = WordSetModel(name: name, words: words.map{ WordModel(text: $0) },
                                attachSharp: attachSharp,
                                generateCombinations: generateCombinations)
        modelContext.insert(newSet)
        
        try? modelContext.save()
        
        return newSet
    }
    
    func deleteWordSet(_ wordSet: WordSetModel) {
        modelContext.delete(wordSet)
        self.save()
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
