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

    private enum TypoScript {
        case korean
        case latin
        case unsupported
    }

    private func typoVariants(for tag: String, intensity: TypoVariantIntensity) -> [String] {
        guard tag.count >= minimumTypoTagLength else {
            return []
        }

        switch detectTypoScript(for: tag) {
        case .korean:
            return koreanTypoVariants(for: tag, intensity: intensity)
        case .latin:
            return latinTypoVariants(for: tag, intensity: intensity)
        case .unsupported:
            return []
        }
    }

    private func latinTypoVariants(for tag: String, intensity: TypoVariantIntensity) -> [String] {
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
        let lowerString = String(character).lowercased()
        guard lowerString.count == 1,
              let lower = lowerString.first,
              let neighbors = keyboardNeighborMap[lower],
              let firstNeighbor = neighbors.first else {
            return nil
        }

        let originalString = String(character)
        if originalString == originalString.uppercased() {
            let upperNeighborString = String(firstNeighbor).uppercased()
            if upperNeighborString.count == 1,
               let upperNeighbor = upperNeighborString.first {
                return upperNeighbor
            }
        }

        return firstNeighbor
    }

    private func koreanTypoVariants(for tag: String, intensity: TypoVariantIntensity) -> [String] {
        let maxVariantsPerTag: Int
        switch intensity {
        case .low:
            maxVariantsPerTag = 1
        case .medium:
            maxVariantsPerTag = 2
        }

        var variants: [String] = []
        var seen = Swift.Set<String>()

        if let substitution = koreanKeystrokeSubstitutionVariant(of: tag),
           substitution != tag,
           !seen.contains(substitution) {
            variants.append(substitution)
            seen.insert(substitution)
        }

        if intensity == .medium,
           let overpress = koreanKeystrokeExtraPressVariant(of: tag),
           overpress != tag,
           !seen.contains(overpress) {
            variants.append(overpress)
            seen.insert(overpress)
        }

        if intensity == .medium,
           variants.count < maxVariantsPerTag,
           let missed = koreanKeystrokeMissedPressVariant(of: tag),
           missed != tag,
           !seen.contains(missed) {
            variants.append(missed)
            seen.insert(missed)
        }

        return Array(variants.prefix(maxVariantsPerTag))
    }

    private func koreanKeystrokeSubstitutionVariant(of tag: String) -> String? {
        mutateMiddleHangulSyllable(in: tag) { keys in
            guard let index = keys.indices.dropFirst().dropLast().first,
                  let neighbor = koreanKeyNeighborMap[keys[index]]?.first else {
                return nil
            }

            var mutated = keys
            mutated[index] = neighbor
            return mutated
        }
    }

    private func koreanKeystrokeExtraPressVariant(of tag: String) -> String? {
        mutateMiddleHangulSyllable(in: tag) { keys in
            guard keys.count == 2 else {
                return nil
            }

            // Typical over-press: repeat initial consonant key as a trailing final consonant key.
            var mutated = keys
            mutated.append(keys[0])
            return mutated
        }
    }

    private func koreanKeystrokeMissedPressVariant(of tag: String) -> String? {
        mutateMiddleHangulSyllable(in: tag) { keys in
            guard keys.count >= 3 else {
                return nil
            }

            // Drop one trailing key (usually final consonant) if syllable stays valid.
            var mutated = keys
            mutated.removeLast()
            return mutated
        }
    }

    private func mutateMiddleHangulSyllable(in tag: String, mutation: ([Character]) -> [Character]?) -> String? {
        var chars = Array(tag)
        guard chars.count >= 3 else {
            return nil
        }

        for index in 1..<(chars.count - 1) {
            guard let keys = hangulSyllableToKeystrokes(chars[index]),
                  let mutatedKeys = mutation(keys),
                  let mutatedSyllable = keystrokesToHangulSyllable(mutatedKeys),
                  mutatedSyllable != chars[index] else {
                continue
            }

            chars[index] = mutatedSyllable
            return String(chars)
        }

        return nil
    }

    private func hangulSyllableToKeystrokes(_ character: Character) -> [Character]? {
        guard let (initial, medial, final) = decomposeHangulSyllable(character),
              let initialKey = koreanInitialKeyMap[initial],
              let medialKey = koreanMedialKeyMap[medial] else {
            return nil
        }

        var keys: [Character] = [initialKey, medialKey]
        if final != 0 {
            guard let finalKey = koreanFinalKeyMap[final] else {
                return nil
            }
            keys.append(finalKey)
        }
        return keys
    }

    private func keystrokesToHangulSyllable(_ keys: [Character]) -> Character? {
        guard keys.count >= 2 && keys.count <= 3,
              let initial = koreanInitialKeyReverseMap[keys[0]],
              let medial = koreanMedialKeyReverseMap[keys[1]] else {
            return nil
        }

        let final: Int
        if keys.count == 3 {
            guard let mappedFinal = koreanFinalKeyReverseMap[keys[2]] else {
                return nil
            }
            final = mappedFinal
        } else {
            final = 0
        }

        return composeHangulSyllable(initial: initial, medial: medial, final: final)
    }

    private func decomposeHangulSyllable(_ character: Character) -> (initial: Int, medial: Int, final: Int)? {
        guard let scalar = character.unicodeScalars.first,
              character.unicodeScalars.count == 1,
              hangulSyllableRange.contains(scalar.value) else {
            return nil
        }

        let syllableOffset = Int(scalar.value - hangulSyllableRange.lowerBound)
        let initialIndex = syllableOffset / (hangulVowelCount * hangulFinalCount)
        let medialAndFinal = syllableOffset % (hangulVowelCount * hangulFinalCount)
        let medialIndex = medialAndFinal / hangulFinalCount
        let finalIndex = medialAndFinal % hangulFinalCount
        return (initialIndex, medialIndex, finalIndex)
    }

    private func composeHangulSyllable(initial: Int, medial: Int, final: Int) -> Character? {
        guard (0..<hangulInitialCount).contains(initial),
              (0..<hangulVowelCount).contains(medial),
              (0..<hangulFinalCount).contains(final) else {
            return nil
        }

        let rebuilt = (initial * hangulVowelCount * hangulFinalCount) + (medial * hangulFinalCount) + final
        let unicodeValue = hangulSyllableRange.lowerBound + UInt32(rebuilt)
        guard let scalar = UnicodeScalar(unicodeValue) else {
            return nil
        }

        return Character(String(scalar))
    }

    private func detectTypoScript(for tag: String) -> TypoScript {
        let chars = Array(tag)
        guard !chars.isEmpty else {
            return .unsupported
        }

        var hangulCount = 0
        var latinCount = 0

        for character in chars {
            if isHangulSyllable(character) {
                hangulCount += 1
            } else if isLatinLetter(character) {
                latinCount += 1
            }
        }

        guard hangulCount > 0 || latinCount > 0 else {
            return .unsupported
        }

        if hangulCount > latinCount {
            return .korean
        }

        if latinCount > hangulCount {
            return .latin
        }

        // Mixed tags with equal influence: keep conservative and avoid unsafe-looking typos.
        return .unsupported
    }

    private func isHangulSyllable(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first,
              character.unicodeScalars.count == 1 else {
            return false
        }

        return (0xAC00...0xD7A3).contains(scalar.value)
    }

    private func isLatinLetter(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first,
              character.unicodeScalars.count == 1 else {
            return false
        }

        return (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value)
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

    private var koreanKeyNeighborMap: [Character: [Character]] {
        [
            "q": ["w", "a"], "w": ["q", "e", "s"], "e": ["w", "r", "d"], "r": ["e", "t", "f"], "t": ["r", "y", "g"],
            "y": ["t", "u", "h"], "u": ["y", "i", "j"], "i": ["u", "o", "k"], "o": ["i", "p", "l"], "p": ["o", "l"],
            "a": ["q", "s", "z"], "s": ["a", "d", "w", "x"], "d": ["s", "f", "e", "c"], "f": ["d", "g", "r", "v"], "g": ["f", "h", "t", "b"],
            "h": ["g", "j", "y", "n"], "j": ["h", "k", "u", "m"], "k": ["j", "l", "i"], "l": ["k", "o", "p"],
            "z": ["a", "x"], "x": ["z", "c", "s"], "c": ["x", "v", "d"], "v": ["c", "b", "f"], "b": ["v", "n", "g"], "n": ["b", "m", "h"], "m": ["n", "j"]
        ]
    }

    private var koreanInitialKeyMap: [Int: Character] {
        [
            0: "r", 1: "R", 2: "s", 3: "e", 4: "E", 5: "f", 6: "a", 7: "q", 8: "Q", 9: "t",
            10: "T", 11: "d", 12: "w", 13: "W", 14: "c", 15: "z", 16: "x", 17: "v", 18: "g"
        ]
    }

    private var koreanMedialKeyMap: [Int: Character] {
        [
            0: "k", 1: "o", 2: "i", 4: "j", 5: "p", 6: "u", 8: "h", 12: "y", 13: "n", 17: "b", 18: "m", 20: "l"
        ]
    }

    private var koreanFinalKeyMap: [Int: Character] {
        [
            1: "r", 2: "R", 4: "s", 7: "e", 8: "f", 16: "a", 17: "q", 19: "t", 20: "T", 21: "d",
            22: "w", 23: "c", 24: "z", 25: "x", 26: "v", 27: "g"
        ]
    }

    private var koreanInitialKeyReverseMap: [Character: Int] {
        Dictionary(uniqueKeysWithValues: koreanInitialKeyMap.map { ($1, $0) })
    }

    private var koreanMedialKeyReverseMap: [Character: Int] {
        Dictionary(uniqueKeysWithValues: koreanMedialKeyMap.map { ($1, $0) })
    }

    private var koreanFinalKeyReverseMap: [Character: Int] {
        Dictionary(uniqueKeysWithValues: koreanFinalKeyMap.map { ($1, $0) })
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

    private let hangulSyllableRange: ClosedRange<UInt32> = 0xAC00...0xD7A3
    private let hangulInitialCount: Int = 19
    private let hangulVowelCount: Int = 21
    private let hangulFinalCount: Int = 28

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
