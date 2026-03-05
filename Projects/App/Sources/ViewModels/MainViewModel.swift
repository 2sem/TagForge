import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.toyboy2.tagforge", category: "MainViewModel")

struct GeneratedTag: Identifiable {
    let id = UUID();
    let text: String;
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var wordSets: [WordSetModel] = []
    @Published var currentWordSet: WordSetModel!
    @Published var generatedTagList: [GeneratedTag] = []
    @Published var showingTagSheet: Bool = false
    @Published var isSyncing: Bool = true

    var generatedTagsString: String {
        let separator = currentWordSet.attachSharp ? " " : ", ";
        return generatedTagList.map(\.text).joined(separator: separator);
    }
    
    private let storageManager: WordSetManager
    private var cancellables = Swift.Set<AnyCancellable>()
    
    init(storageManager: WordSetManager = .shared) {
        self.storageManager = storageManager
        // NSManagedObjectContextDidSave Notification 구독
        storageManager.remoteChangePublisher
            .combineLatest($isSyncing)
            .filter { (_, isSyncing) in isSyncing }
            .map { (notification, _) in notification }
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (notification) in
                print("WordSetManager.remomteChange. \(notification.userInfo)")
                self?.loadWordSets()
                self?.isSyncing = false
            }
            .store(in: &cancellables)
        
        // 초기 데이터 로드
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
        
        let currentWordSet = self.storageManager.createWordSet(words: [], attachSharp: false, generateCombinations: false)
        self.currentWordSet = currentWordSet
        wordSets.append(currentWordSet)
    }
    
    private func loadCurrentSet() {
        currentWordSet = wordSets.first;
    }

    func loadWord(set: WordSetModel) {
        currentWordSet = set;
    }
    
    func addWord(_ word: String) -> Bool {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = currentWordSet.words ?? []

        guard !trimmedWord.isEmpty, !words.contains(where: { $0.text == trimmedWord }) else { return false }

        // order: 현재 words 중 최대 order + 1
        let maxOrder = words.map { $0.order }.max() ?? -1
        let newWord = WordModel(text: trimmedWord, order: maxOrder + 1, wordSet: currentWordSet)
        currentWordSet.words?.append(newWord)
        storageManager.save()
        return true
    }
    
    /// Parses `input` into individual tokens and adds each one as a word.
    ///
    /// Supported formats:
    /// - Hashtag strings: `#travel #Seoul #food` → splits on whitespace, strips leading `#`
    /// - Comma / newline separated: `travel, Seoul, food` → splits on `,` or `\n`, trims whitespace
    ///
    /// - Returns: A tuple `(added, skipped)` where `skipped` counts duplicates that were not inserted.
    func addWords(_ input: String) -> (added: Int, skipped: Int) {
        let tokens: [String]
        if input.contains("#") {
            tokens = input
                .components(separatedBy: .whitespaces)
                .map { $0.hasPrefix("#") ? String($0.dropFirst()) : $0 }
        } else {
            tokens = input
                .components(separatedBy: CharacterSet(charactersIn: ",\n"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }

        let nonEmpty = tokens.filter { !$0.isEmpty }
        logger.debug("addWords: parsed \(nonEmpty.count) tokens from input")

        var added = 0
        var skipped = 0
        for token in nonEmpty {
            if addWord(token) {
                added += 1
            } else {
                skipped += 1
            }
        }
        logger.info("addWords: added=\(added) skipped=\(skipped)")
        return (added, skipped)
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
        currentWordSet = self.storageManager.createWordSet(name: name, words: [], attachSharp: false, generateCombinations: false)
        wordSets.append(currentWordSet)
        storageManager.save()
    }
    
    func generateTags() {
        // 1. 옵션 적용 함수 (hash mode에서는 자동으로 공백을 _로 변환)
        func applyOptions(to tag: String) -> String {
            var tag = tag;
            if currentWordSet.attachSharp {
                tag = tag.replacingOccurrences(of: " ", with: "_");
            }
            return tag;
        }
        // 2. 원본 단어 리스트
        let originalWords = currentWordSet.words?.map { $0.text } ?? [];
        // 3. 옵션 적용된 단어 리스트
        var tags: [String] = originalWords.map { applyOptions(to: $0) };
        // 4. 조합 생성 및 옵션 적용
        if currentWordSet.generateCombinations {
            let combinations = generateCombinations(of: originalWords);
            tags.append(contentsOf: combinations.map { applyOptions(to: $0) });
        }
        // 5. attachSharp 옵션이 켜져 있으면 마지막에 한 번만 #을 붙임
        if currentWordSet.attachSharp {
            tags = tags.map { tag in
                tag.hasPrefix("#") ? tag : "#" + tag;
            };
        }
        // 6. Populate tag list and present sheet
        generatedTagList = tags.map { GeneratedTag(text: $0) };
        showingTagSheet = true;
    }

    private func generateCombinations(of words: [String]) -> [String] {
        var combinations = [String]()
        let maxLength = min(currentWordSet.maxCombinationLength, words.count);
        guard maxLength >= 2 else { return combinations }
        for length in 2...maxLength {
            for combination in words.combinations(ofLength: length) {
                combinations.append(combination.joined())
            }
        }
        return combinations
    }
    
    func renameCurrentSet(to newName: String) {
        currentWordSet.name = newName
        storageManager.save()
    }
}
