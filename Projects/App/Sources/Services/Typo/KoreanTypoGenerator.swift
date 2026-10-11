import Foundation

/// Ranked, quality-filtered typo candidates for Hangul text, modeled on 2-beolsik keystrokes.
struct KoreanTypoGenerator {
    /// One keystroke-level mutation rule: how likely it is and how to produce mutated keystroke sequences.
    private struct Rule {
        let kind: TypoCandidateRule
        let score: Double
        let variants: ([Character]) -> [[Character]]
    }

    private static let rules: [Rule] = [
        Rule(kind: .koreanAdjacentKeySubstitution, score: 3.5, variants: adjacentKeySubstitutions),
        Rule(kind: .koreanKeystrokeTransposition, score: 2.8, variants: keystrokeTranspositions),
        Rule(kind: .koreanMissedKeystroke, score: 2.9, variants: missedKeystrokes),
        Rule(kind: .koreanDoublePress, score: 2.7, variants: doublePresses)
    ]

    /// 2-beolsik keys of the initials that may be over-pressed into a final: ㄱ ㄴ ㄹ ㅁ ㅂ ㅅ.
    private static let commonDoublePressKeys: Swift.Set<Character> = ["r", "s", "f", "a", "q", "t"]

    /// Known uncanny outputs that pass the structural filters but should never be shown.
    private static let blockedOutputs: Swift.Set<String> = [
        "카커오톡", "맛짖", "서울오행", "서울요행", "Seoul오행", "Seoul요행",
        "카캬오톡", "카마오톡", "셔울여행", "소울여행", "맛잡", "맛잽",
        "카캬오톡Review", "카마오톡Review", "셔울여행Review", "소울여행Review", "맛잡Review", "맛잽Review"
    ]

    /// Final-consonant transitions (by final index) that look like a real slip.
    private static let allowedFinalTransitions: Swift.Set<[Int]> = [
        [17, 16], [17, 19], [19, 17], [19, 20], [16, 17], [16, 19], [8, 4], [8, 16]
    ]

    /// Medial-vowel transitions (by medial index) that look like a real slip.
    private static let allowedMedialTransitions: Swift.Set<[Int]> = [
        [0, 4], [4, 0], [4, 20], [20, 4], [13, 17], [17, 13], [8, 12], [12, 8]
    ]

    /// Medial jumps that read as vowel drift rather than a keyboard slip.
    private static let driftedMedialTransitions: Swift.Set<[Int]> = [
        [5, 8], [5, 12], [6, 8], [6, 12]
    ]

    func rankedCandidates(for text: String) -> [TypoCandidate] {
        let chars = Array(text)
        var bestByValue: [String: TypoCandidate] = [:]

        for index in chars.indices {
            guard let keystrokes = Hangul.keystrokes(for: chars[index]) else {
                continue
            }

            for rule in Self.rules {
                for variant in rule.variants(keystrokes) {
                    guard let syllable = Hangul.syllable(from: variant), syllable != chars[index] else {
                        continue
                    }
                    var mutated = chars
                    mutated[index] = syllable
                    let candidate = TypoCandidate(value: String(mutated), score: rule.score, rule: rule.kind)
                    bestByValue.insertKeepingBest(candidate)
                }
            }
        }

        return bestByValue.values
            .filter { passesQualityFilter(original: text, candidate: $0) }
            .sortedByRank()
    }

    // MARK: - Keystroke rules

    /// Neighbor swap on any key except the initial consonant (index 0); first two neighbors only.
    private static func adjacentKeySubstitutions(for keystrokes: [Character]) -> [[Character]] {
        var variants: [[Character]] = []
        var seen = Swift.Set<String>()

        for index in keystrokes.indices where index > 0 {
            for neighbor in physicalNeighbors(of: keystrokes[index]).prefix(2) {
                var mutated = keystrokes
                mutated[index] = neighbor
                if seen.insert(String(mutated)).inserted {
                    variants.append(mutated)
                }
            }
        }
        return variants
    }

    private static func keystrokeTranspositions(for keystrokes: [Character]) -> [[Character]] {
        guard keystrokes.count >= 2 else {
            return []
        }

        var variants: [[Character]] = []
        var seen = Swift.Set<String>()
        for index in 0..<(keystrokes.count - 1) where keystrokes[index] != keystrokes[index + 1] {
            var mutated = keystrokes
            mutated.swapAt(index, index + 1)
            if seen.insert(String(mutated)).inserted {
                variants.append(mutated)
            }
        }
        return variants
    }

    /// Trailing final-consonant key omitted.
    private static func missedKeystrokes(for keystrokes: [Character]) -> [[Character]] {
        keystrokes.count == 3 ? [Array(keystrokes.prefix(2))] : []
    }

    /// Repeated initial consonant becomes a tail final consonant (high-confidence over-press only).
    /// Limited to the common final consonants; rare finals (`캌`, `댇`, `햏`) and the silent `ㅇ`
    /// (`이` -> `잉` changes the word) read as machine-made rather than a stuck key.
    private static func doublePresses(for keystrokes: [Character]) -> [[Character]] {
        guard keystrokes.count == 2, commonDoublePressKeys.contains(keystrokes[0]) else {
            return []
        }
        return [[keystrokes[0], keystrokes[1], keystrokes[0]]]
    }

    private static func physicalNeighbors(of key: Character) -> [Character] {
        let string = String(key)
        let isUppercase = string == string.uppercased()
        let lowered = string.lowercased()

        guard lowered.count == 1,
              let lookup = lowered.first,
              let neighbors = KeyboardLayout.neighbors[lookup] else {
            return []
        }
        guard isUppercase else {
            return neighbors
        }
        return neighbors.compactMap { neighbor in
            let upper = String(neighbor).uppercased()
            return upper.count == 1 ? upper.first : nil
        }
    }

    // MARK: - Quality filter

    private func passesQualityFilter(original: String, candidate: TypoCandidate) -> Bool {
        guard candidate.value != original,
              candidate.rule.isKorean,
              !Self.blockedOutputs.contains(candidate.value) else {
            return false
        }

        let originalScalars = Array(original.unicodeScalars)
        let candidateScalars = Array(candidate.value.unicodeScalars)
        guard originalScalars.count == candidateScalars.count else {
            return false
        }

        let scalarDiffCount = zip(originalScalars, candidateScalars).filter { $0 != $1 }.count
        guard scalarDiffCount == 1, let change = changedSyllable(original: original, candidate: candidate.value) else {
            return false
        }

        let before = change.before
        let after = change.after

        if before.initial != after.initial, before.medial != after.medial {
            return false
        }
        if before.initial != after.initial, before.final != after.final {
            return false
        }
        if Self.driftedMedialTransitions.contains([before.medial, after.medial]) {
            return false
        }
        if before.final != after.final,
           !isAllowedFinalTransition(from: before.final, to: after.final, rule: candidate.rule) {
            return false
        }
        if before.medial != after.medial, !Self.allowedMedialTransitions.contains([before.medial, after.medial]) {
            return false
        }
        return true
    }

    /// Final-consonant changes: substitutions must be on the allow-list; dropping the trailing final
    /// (`x -> none`) is only valid for the missed-keystroke rule, and adding one (`none -> x`) only
    /// for the double-press rule, which already guarantees the new final repeats the initial key.
    private func isAllowedFinalTransition(from before: Int, to after: Int, rule: TypoCandidateRule) -> Bool {
        switch (before, after) {
        case (_, 0):
            return rule == .koreanMissedKeystroke
        case (0, _):
            return rule == .koreanDoublePress
        default:
            return Self.allowedFinalTransitions.contains([before, after])
        }
    }

    private func changedSyllable(original: String, candidate: String) -> (before: Hangul.Jamo, after: Hangul.Jamo)? {
        let lhs = Array(original)
        let rhs = Array(candidate)
        guard lhs.count == rhs.count else {
            return nil
        }

        let changed = lhs.indices.filter { lhs[$0] != rhs[$0] }
        guard changed.count == 1,
              let index = changed.first,
              let before = Hangul.decompose(lhs[index]),
              let after = Hangul.decompose(rhs[index]) else {
            return nil
        }
        return (before, after)
    }
}
