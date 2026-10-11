import Foundation

/// Script family of a single character, used to split a tag into homogeneous segments.
enum TypoScript: Equatable {
    case korean
    case latin
    case other

    init(_ character: Character) {
        if Hangul.isSyllable(character) {
            self = .korean
        } else if character.isBasicLatinLetter {
            self = .latin
        } else {
            self = .other
        }
    }
}

/// A run of consecutive characters sharing the same `TypoScript`.
struct TypoSegment: Equatable {
    let text: String
    let script: TypoScript

    static func split(_ tag: String) -> [TypoSegment] {
        var segments: [TypoSegment] = []
        var currentText = ""
        var currentScript: TypoScript?

        for character in tag {
            let script = TypoScript(character)
            if script == currentScript {
                currentText.append(character)
                continue
            }
            if let currentScript, !currentText.isEmpty {
                segments.append(TypoSegment(text: currentText, script: currentScript))
            }
            currentScript = script
            currentText = String(character)
        }

        if let currentScript, !currentText.isEmpty {
            segments.append(TypoSegment(text: currentText, script: currentScript))
        }
        return segments
    }
}

enum TypoCandidateRule: Equatable {
    case repeatedLetterOmission
    case keyboardNeighborSubstitution
    case adjacentTransposition
    case koreanAdjacentKeySubstitution
    case koreanKeystrokeTransposition
    case koreanMissedKeystroke
    case koreanDoublePress

    var isKorean: Bool {
        switch self {
        case .koreanAdjacentKeySubstitution, .koreanKeystrokeTransposition, .koreanMissedKeystroke, .koreanDoublePress:
            return true
        case .repeatedLetterOmission, .keyboardNeighborSubstitution, .adjacentTransposition:
            return false
        }
    }
}

struct TypoCandidate: Equatable {
    let value: String
    let score: Double
    let rule: TypoCandidateRule
    /// True when the candidate mutates the Latin side of a mixed Korean + Latin tag.
    var isLatinSideFallback: Bool = false
}

extension Sequence where Element == TypoCandidate {
    /// Highest score first; ties broken by value so output is deterministic.
    func sortedByRank() -> [TypoCandidate] {
        sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.value < rhs.value : lhs.score > rhs.score
        }
    }
}

extension Dictionary where Key == String, Value == TypoCandidate {
    /// Stores `candidate` unless an equal-or-better candidate with the same value is already present.
    mutating func insertKeepingBest(_ candidate: TypoCandidate) {
        if let existing = self[candidate.value], existing.score >= candidate.score {
            return
        }
        self[candidate.value] = candidate
    }
}

extension Character {
    /// ASCII A-Z / a-z only (single scalar).
    var isBasicLatinLetter: Bool {
        guard unicodeScalars.count == 1, let scalar = unicodeScalars.first else {
            return false
        }
        return (0x41...0x5A).contains(scalar.value) || (0x61...0x7A).contains(scalar.value)
    }

    var isBasicLatinVowel: Bool {
        guard isBasicLatinLetter else {
            return false
        }
        return "aeiou".contains(lowercased())
    }
}
