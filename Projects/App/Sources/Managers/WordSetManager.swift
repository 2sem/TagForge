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
import OSLog

private let logger = Logger(subsystem: "com.toyboy2.tagforge", category: "iCloudSync")

@MainActor
class WordSetManager {
    static let shared = WordSetManager()
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private var cancellables = Swift.Set<AnyCancellable>()

    private init() {
        do {
            let config: ModelConfiguration = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.toyboy2.tagforge"))
            modelContainer = try ModelContainer(for: WordSetModel.self, WordModel.self, configurations: config)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        NSPersistentCloudKitContainer.eventChangedPublisher
            .sink { event in
                let type: String
                switch event.type {
                case .setup:  type = "setup"
                case .import: type = "import"
                case .export: type = "export"
                @unknown default: type = "unknown"
                }

                let duration = event.endDate.map { String(format: "%.2fs", $0.timeIntervalSince(event.startDate)) } ?? "in progress"

                if event.succeeded {
                    logger.info("[\(type)] succeeded — \(duration)")
                } else if let error = event.error {
                    logger.error("[\(type)] failed — \(duration) — \(error)")
                } else {
                    logger.warning("[\(type)] ended without success — \(duration)")
                }
            }
            .store(in: &cancellables)
    }
    
    // CloudKit import event publisher — fires when the initial iCloud import finishes
    // (regardless of whether data was found), which is the earliest safe moment to create defaults.
    var cloudKitImportEventPublisher: AnyPublisher<NSPersistentCloudKitContainer.Event, Never> {
        NSPersistentCloudKitContainer.eventChangedPublisher
            .filter { $0.type == .import && $0.endDate != nil }
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
