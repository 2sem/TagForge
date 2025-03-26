import Foundation

@MainActor
class MainViewModel: ObservableObject {
    @Published var wordSets: [WordSetModel] = []
    @Published var currentWordSet: WordSetModel!
    @Published var generatedTags: String = ""
    
    private let storageManager: WordSetManager
    
    init(storageManager: WordSetManager = .shared) {
        self.storageManager = storageManager
        loadWordSets()
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
        
        currentWordSet = self.storageManager.createWordSet(words: [], replaceSpaces: false, attachSharp: false, generateCombinations: false)
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
        guard !trimmedWord.isEmpty, !currentWordSet.words.contains(trimmedWord) else { return false }
        
        currentWordSet.words.append(trimmedWord)
        storageManager.save()
        return true
    }
    
    func deleteWord(_ word: String) {
        if let index = currentWordSet.words.firstIndex(where: { $0 == word }) {
            currentWordSet.words.remove(at: index)
            storageManager.save()
        }
    }
    
    func deleteWords(at offsets: IndexSet) {
        currentWordSet.words.remove(atOffsets: offsets)
        storageManager.save()
    }
    
    func createNewSet(name: String) {
        currentWordSet = self.storageManager.createWordSet(name: name, words: [], replaceSpaces: false, attachSharp: false, generateCombinations: false)
        wordSets.append(currentWordSet)
        storageManager.save()
    }
    
    func generateTags() {
        var tags = currentWordSet.words.map { word in
            var tag = word
            if currentWordSet.replaceSpaces {
                tag = tag.replacingOccurrences(of: " ", with: "_")
            }
            if currentWordSet.attachSharp {
                tag = "#" + tag
            }
            return tag
        }
        
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
