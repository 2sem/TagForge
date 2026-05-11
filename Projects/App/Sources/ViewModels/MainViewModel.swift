import Foundation
import Combine
import CoreData
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.toyboy2.tagforge", category: "MainViewModel")
private let selectedWordSetIDKey = "selectedWordSetID"

struct GeneratedTag: Identifiable {
    let id = UUID();
    let text: String;
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var wordSets: [WordSetModel] = []
    @Published var currentWordSet: WordSetModel! {
        didSet {
            saveCurrentSetID();
        }
    }
    @Published var generatedTagList: [GeneratedTag] = []
    @Published var showingTagSheet: Bool = false
    @Published var isSyncing: Bool = true
    @Published var syncMessage: String = NSLocalizedString("sync.message.connecting", comment: "")

    var generatedTagsString: String {
        let separator = currentWordSet.attachSharp ? " " : ", ";
        return generatedTagList.map(\.text).joined(separator: separator);
    }
    
    private let storageManager: WordSetManager
    private var cancellables = Swift.Set<AnyCancellable>()
    init(storageManager: WordSetManager = .shared) {
        self.storageManager = storageManager

        NSPersistentCloudKitContainer.eventChangedPublisher
            .filter { $0.endDate == nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event.type {
                case .setup:  self?.syncMessage = NSLocalizedString("sync.message.connecting", comment: "")
                case .import: self?.syncMessage = NSLocalizedString("sync.message.loading", comment: "")
                case .export: self?.syncMessage = NSLocalizedString("sync.message.saving", comment: "")
                @unknown default: break
                }
            }
            .store(in: &cancellables)

        storageManager.syncReadyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadWordSets()
                self?.isSyncing = false
            }
            .store(in: &cancellables)

        wordSets = storageManager.loadWordSets()
        if !wordSets.isEmpty {
            preserveOrLoadCurrentSet()
        }
    }

    func loadWordSets() {
        wordSets = WordSetManager.shared.loadWordSets()

        createDefaultWordSetIfNeeded()

        preserveOrLoadCurrentSet()
    }

    func createDefaultWordSetIfNeeded() {
        guard wordSets.isEmpty else {
            return
        }

        let newSet = self.storageManager.createWordSet(words: [], attachSharp: false, generateCombinations: false)
        self.currentWordSet = newSet
        wordSets.append(newSet)
    }

    /// After a reload, keep the previously selected word set when it still exists in the
    /// refreshed list (matched by `PersistentIdentifier`). Falls back to the UserDefaults-
    /// persisted ID, then to the first available word set when no prior selection is found.
    private func preserveOrLoadCurrentSet() {
        // 1. In-memory selection takes priority (already set this session).
        if let previousID = currentWordSet?.persistentModelID,
           let preserved = wordSets.first(where: { $0.persistentModelID == previousID }) {
            currentWordSet = preserved;
            return;
        }

        // 2. Try restoring from UserDefaults (survives cold launch / reinstall-after-backup).
        if let data = UserDefaults.standard.data(forKey: selectedWordSetIDKey),
           let storedID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data),
           let matched = wordSets.first(where: { $0.persistentModelID == storedID }) {
            logger.info("preserveOrLoadCurrentSet: restored selection from UserDefaults");
            currentWordSet = matched;
            return;
        }

        // 3. Nothing persisted — fall back to the first word set.
        currentWordSet = wordSets.first;
    }

    /// Encodes the current word set's `PersistentIdentifier` and writes it to `UserDefaults`.
    /// Called automatically via `didSet` on `currentWordSet`.
    private func saveCurrentSetID() {
        guard let id = currentWordSet?.persistentModelID else {
            UserDefaults.standard.removeObject(forKey: selectedWordSetIDKey);
            return;
        }
        do {
            let data = try JSONEncoder().encode(id);
            UserDefaults.standard.set(data, forKey: selectedWordSetIDKey);
        } catch {
            logger.error("saveCurrentSetID: failed to encode PersistentIdentifier — \(error)");
        }
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
        var baseTags: [String] = originalWords.map { applyOptions(to: $0) };

        // 4. 조합 생성 및 옵션 적용
        if currentWordSet.generateCombinations {
            let combinations = generateCombinations(of: originalWords);
            baseTags.append(contentsOf: combinations.map { applyOptions(to: $0) });
        }

        // 5. attachSharp 옵션이 켜져 있으면 마지막에 한 번만 #을 붙임
        if currentWordSet.attachSharp {
            baseTags = baseTags.map { tag in
                tag.hasPrefix("#") ? tag : "#" + tag;
            };
        }

        // 6. typo variants (MVP): deterministic, one operation per tag, conservative cap
        let tags: [String]
        if currentWordSet.includeTypoVariants {
            tags = appendTypoVariants(to: baseTags, intensity: currentWordSet.typoVariantIntensity)
        } else {
            tags = deduplicatedPreservingOrder(baseTags)
        }

        // 7. Populate tag list and present sheet
        generatedTagList = tags.map { GeneratedTag(text: $0) };
        showingTagSheet = true;
    }

    private func appendTypoVariants(to baseTags: [String], intensity: TypoVariantIntensity) -> [String] {
        let uniqueBaseTags = deduplicatedPreservingOrder(baseTags)
        var finalTags = uniqueBaseTags
        var seen = Swift.Set(uniqueBaseTags)
        var typoAddedCount = 0

        for baseTag in uniqueBaseTags {
            guard typoAddedCount < typoVariantTotalCap else {
                break
            }

            let candidates = typoVariants(for: baseTag, intensity: intensity)
            for candidate in candidates {
                guard typoAddedCount < typoVariantTotalCap else {
                    break
                }
                guard !seen.contains(candidate) else {
                    continue
                }
                finalTags.append(candidate)
                seen.insert(candidate)
                typoAddedCount += 1
            }
        }

        return finalTags
    }

    private func typoVariants(for tag: String, intensity: TypoVariantIntensity) -> [String] {
        guard tag.count >= minimumTypoTagLength else {
            return []
        }

        let maxVariantsPerTag: Int
        switch intensity {
        case .low:
            maxVariantsPerTag = 1
        case .medium:
            maxVariantsPerTag = 2
        }

        var variants: [String] = []
        var seen = Swift.Set<String>()

        if let substitution = keyboardNeighborSubstitutionVariant(of: tag), substitution != tag {
            variants.append(substitution)
            seen.insert(substitution)
        }

        if let transposed = middleAdjacentTranspositionVariant(of: tag),
           transposed != tag,
           !seen.contains(transposed) {
            variants.append(transposed)
            seen.insert(transposed)
        }

        if intensity == .medium,
           let omitted = middleOmissionVariant(of: tag),
           omitted != tag,
           !seen.contains(omitted) {
            variants.append(omitted)
            seen.insert(omitted)
        }

        return Array(variants.prefix(maxVariantsPerTag))
    }

    private func keyboardNeighborSubstitutionVariant(of tag: String) -> String? {
        var chars = Array(tag)
        guard chars.count >= 3 else {
            return nil
        }

        for index in 1..<(chars.count - 1) {
            guard let replacement = keyboardNeighbor(for: chars[index]) else {
                continue
            }
            chars[index] = replacement
            return String(chars)
        }

        return nil
    }

    private func middleAdjacentTranspositionVariant(of tag: String) -> String? {
        var chars = Array(tag)
        guard chars.count >= 4 else {
            return nil
        }

        // Avoid edge swaps: swap only where both characters are not first/last.
        for index in 1..<(chars.count - 2) {
            guard chars[index] != chars[index + 1] else {
                continue
            }
            chars.swapAt(index, index + 1)
            return String(chars)
        }

        return nil
    }

    private func middleOmissionVariant(of tag: String) -> String? {
        let chars = Array(tag)
        guard chars.count >= 4 else {
            return nil
        }

        // Omit only from the middle (never first or last).
        for index in 1..<(chars.count - 1) {
            var candidate = chars
            candidate.remove(at: index)
            return String(candidate)
        }

        return nil
    }

    private func keyboardNeighbor(for character: Character) -> Character? {
        let lower = Character(String(character).lowercased())
        guard let neighbors = keyboardNeighborMap[lower],
              let firstNeighbor = neighbors.first else {
            return nil
        }

        if String(character) == String(character).uppercased() {
            return Character(String(firstNeighbor).uppercased())
        }
        return firstNeighbor
    }

    private var keyboardNeighborMap: [Character: [Character]] {
        [
            "a": ["s", "q", "w", "z"],
            "b": ["v", "g", "h", "n"],
            "c": ["x", "d", "f", "v"],
            "d": ["s", "e", "r", "f", "c", "x"],
            "e": ["w", "s", "d", "r"],
            "f": ["d", "r", "t", "g", "v", "c"],
            "g": ["f", "t", "y", "h", "b", "v"],
            "h": ["g", "y", "u", "j", "n", "b"],
            "i": ["u", "j", "k", "o"],
            "j": ["h", "u", "i", "k", "m", "n"],
            "k": ["j", "i", "o", "l", "m"],
            "l": ["k", "o", "p"],
            "m": ["n", "j", "k"],
            "n": ["b", "h", "j", "m"],
            "o": ["i", "k", "l", "p"],
            "p": ["o", "l"],
            "q": ["w", "a"],
            "r": ["e", "d", "f", "t"],
            "s": ["a", "w", "e", "d", "x", "z"],
            "t": ["r", "f", "g", "y"],
            "u": ["y", "h", "j", "i"],
            "v": ["c", "f", "g", "b"],
            "w": ["q", "a", "s", "e"],
            "x": ["z", "s", "d", "c"],
            "y": ["t", "g", "h", "u"],
            "z": ["a", "s", "x"]
        ]
    }

    private func deduplicatedPreservingOrder(_ tags: [String]) -> [String] {
        var seen = Swift.Set<String>()
        var result: [String] = []
        for tag in tags {
            if seen.insert(tag).inserted {
                result.append(tag)
            }
        }
        return result
    }

    private var minimumTypoTagLength: Int { 4 }
    private var typoVariantTotalCap: Int { 200 }

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
