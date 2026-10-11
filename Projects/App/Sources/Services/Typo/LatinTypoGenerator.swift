import Foundation

/// Ranked, quality-filtered typo candidates for Latin-script text.
struct LatinTypoGenerator {
    private struct PositionedVariant {
        let value: String
        let position: Int
    }

    private static let maxEditDistance = 2

    func rankedCandidates(for text: String, isMixedToken: Bool) -> [TypoCandidate] {
        var bestByValue: [String: TypoCandidate] = [:]

        for omission in repeatedLetterOmissions(of: text) where omission != text {
            bestByValue.insertKeepingBest(TypoCandidate(value: omission, score: 5.0, rule: .repeatedLetterOmission))
        }

        for variant in neighborSubstitutions(of: text) where variant.value != text {
            let score = variant.position == 0 ? 1.2 : 2.7
            bestByValue.insertKeepingBest(TypoCandidate(value: variant.value, score: score, rule: .keyboardNeighborSubstitution))
        }

        for variant in adjacentTranspositions(of: text) where variant.value != text {
            bestByValue.insertKeepingBest(TypoCandidate(
                value: variant.value,
                score: transpositionScore(of: text, at: variant.position),
                rule: .adjacentTransposition
            ))
        }

        return bestByValue.values
            .filter { passesQualityFilter(original: text, candidate: $0, isMixedToken: isMixedToken) }
            .sortedByRank()
    }

    // MARK: - Scoring

    /// Transposition outranks same-row substitution (2.7) but stays below repeated-letter omission (5.0).
    private static let transpositionScore = 3.1
    /// Swapped keys typed by opposite hands are the classic order slip (`Seoul` -> `Soeul`).
    private static let crossHandTranspositionBonus = 0.2
    private static let firstCharacterTranspositionScore = 1.4
    private static let leftHandKeys: Swift.Set<Character> = Swift.Set("qwertasdfgzxcvb")

    private func transpositionScore(of text: String, at position: Int) -> Double {
        guard position > 0 else {
            return Self.firstCharacterTranspositionScore
        }
        let chars = Array(text)
        let pair = [chars[position], chars[position + 1]].map { Self.leftHandKeys.contains(Character($0.lowercased())) }
        let isCrossHand = pair[0] != pair[1]
        return Self.transpositionScore + (isCrossHand ? Self.crossHandTranspositionBonus : 0)
    }

    // MARK: - Generation

    private func repeatedLetterOmissions(of text: String) -> [String] {
        let chars = Array(text)
        guard chars.count >= 2 else {
            return []
        }

        var variants: [String] = []
        var seen = Swift.Set<String>()
        for index in 1..<chars.count where chars[index] == chars[index - 1] && chars[index].isBasicLatinLetter {
            var mutated = chars
            mutated.remove(at: index)
            let value = String(mutated)
            if seen.insert(value).inserted {
                variants.append(value)
            }
        }
        return variants
    }

    private func neighborSubstitutions(of text: String) -> [PositionedVariant] {
        let chars = Array(text)
        guard chars.count >= 3 else {
            return []
        }

        var variants: [PositionedVariant] = []
        var seen = Swift.Set<String>()
        for index in chars.indices {
            for replacement in neighborCandidates(for: chars[index], at: index) {
                var mutated = chars
                mutated[index] = replacement
                let value = String(mutated)
                if seen.insert(value).inserted {
                    variants.append(PositionedVariant(value: value, position: index))
                }
            }
        }
        return variants
    }

    private func adjacentTranspositions(of text: String) -> [PositionedVariant] {
        let chars = Array(text)
        guard chars.count >= 3 else {
            return []
        }

        var variants: [PositionedVariant] = []
        var seen = Swift.Set<String>()
        for index in 0..<(chars.count - 1) {
            guard chars[index].isBasicLatinLetter,
                  chars[index + 1].isBasicLatinLetter,
                  chars[index] != chars[index + 1] else {
                continue
            }
            var mutated = chars
            mutated.swapAt(index, index + 1)
            let value = String(mutated)
            if seen.insert(value).inserted {
                variants.append(PositionedVariant(value: value, position: index))
            }
        }
        return variants
    }

    /// Up to 2 same-row-first neighbors (1 for the first character), keeping the original letter case.
    private func neighborCandidates(for character: Character, at index: Int) -> [Character] {
        let lowered = String(character).lowercased()
        guard lowered.count == 1,
              let lower = lowered.first,
              let neighbors = KeyboardLayout.horizontalFirstNeighbors(of: lower) else {
            return []
        }

        let selected = neighbors.prefix(index == 0 ? 1 : 2)
        let isUppercase = String(character) == String(character).uppercased()
        guard isUppercase else {
            return Array(selected)
        }
        return selected.compactMap { neighbor in
            let upper = String(neighbor).uppercased()
            return upper.count == 1 ? upper.first : nil
        }
    }

    // MARK: - Quality filter

    private func passesQualityFilter(original: String, candidate: TypoCandidate, isMixedToken: Bool) -> Bool {
        guard candidate.value != original else {
            return false
        }

        let originalChars = Array(original)
        let candidateChars = Array(candidate.value)
        let isSameLength = originalChars.count == candidateChars.count

        if isMixedToken, candidate.rule == .keyboardNeighborSubstitution, isSameLength {
            if originalChars.first != candidateChars.first {
                return false
            }

            let changed = originalChars.indices.filter { originalChars[$0] != candidateChars[$0] }
            if changed.count == 1, let index = changed.first {
                let isInterior = index > 0 && index < originalChars.count - 1
                if isInterior, originalChars[index].isBasicLatinVowel, candidateChars[index].isBasicLatinVowel {
                    return false
                }
            }
        }

        let distance = EditDistance.damerauLevenshtein(originalChars, candidateChars, limit: Self.maxEditDistance)
        if distance > Self.maxEditDistance {
            return false
        }

        if isSameLength {
            let sameCount = zip(originalChars, candidateChars).filter { $0 == $1 }.count
            let sameRatio = Double(sameCount) / Double(max(originalChars.count, 1))
            let minimumSameRatio: Double = candidate.rule == .adjacentTransposition ? 0.60 : 0.70
            if sameRatio < minimumSameRatio {
                return false
            }
        }

        return true
    }
}
