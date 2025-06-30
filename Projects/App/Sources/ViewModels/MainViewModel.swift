import Foundation
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var wordSets: [WordSetModel] = []
    @Published var currentWordSet: WordSetModel!
    @Published var generatedTags: String = ""
    @Published var isSyncing: Bool = true
    
    private let storageManager: WordSetManager
    private var cancellables = Swift.Set<AnyCancellable>()
    
    init(storageManager: WordSetManager = .shared) {
        self.storageManager = storageManager
        // NSManagedObjectContextDidSave Notification 구독
        storageManager.remoteChangePublisher
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (notification) in
                print("WordSetManager.remomteChange. \(notification.userInfo)")
                self?.loadWordSets()
                self?.isSyncing = false
            }
            .store(in: &cancellables)
    }
    
    func loadWordSets() {
        wordSets = WordSetManager.shared.loadWordSets()
        
        createDefaultWordSetIfNeeded()
        
        loadCurrentSet()
    }
    
    func createDefaultWordSetIfNeeded() {
        guard wordSets.isEmpty else {
            return
        }
        
        let currentWordSet = self.storageManager.createWordSet(words: [], replaceSpaces: false, attachSharp: false, generateCombinations: false)
        self.currentWordSet = currentWordSet
        wordSets.append(currentWordSet)
    }
    
    private func loadCurrentSet() {
        currentWordSet = wordSets.first
    }
    
    func loadWord(set: WordSetModel) {
        currentWordSet = set
    }
    
    func addWord(_ word: String) -> Bool {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = currentWordSet.words ?? []
        
        guard !trimmedWord.isEmpty, !words.contains(where: { $0.text == trimmedWord }) else { return false }
        
        let newWord = WordModel(text: trimmedWord, wordSet: currentWordSet)
        currentWordSet.words?.append(newWord)
        storageManager.save()
        return true
    }
    
    func deleteWord(_ word: WordModel) {
        if let index = currentWordSet.words?.firstIndex(of: word) {
            currentWordSet.words?.remove(at: index)
            storageManager.deleteWord(word)
        }
    }
    
    func deleteWords(at offsets: IndexSet) {
        let wordsToDelete = offsets.compactMap { currentWordSet.words?[$0] }
        
        for word in wordsToDelete {
            guard let index = currentWordSet.words?.firstIndex(of: word) else {
                continue
            }
            
            currentWordSet.words?.remove(at: index)
            storageManager.deleteWord(word)
        }
    }
    
    func createNewSet(name: String) {
        currentWordSet = self.storageManager.createWordSet(name: name, words: [], replaceSpaces: false, attachSharp: false, generateCombinations: false)
        wordSets.append(currentWordSet)
        storageManager.save()
    }
    
    func generateTags() {
        var tags: [String] = currentWordSet.words?.map { word in
            var tag = word.text
            if currentWordSet.replaceSpaces {
                tag = tag.replacingOccurrences(of: " ", with: "_")
            }
            if currentWordSet.attachSharp {
                tag = "#" + tag
            }
            return tag
        } ?? []
        
        if currentWordSet.generateCombinations {
            tags.append(contentsOf: generateCombinations(of: tags))
        }
        
        generatedTags = tags.joined(separator: ", ")
    }
    
    private func generateCombinations(of words: [String]) -> [String] {
        var combinations = [String]()
        for length in 2...words.count {
            for combination in words.combinations(ofLength: length) {
                combinations.append(combination.joined())
            }
        }
        return combinations
    }
}
