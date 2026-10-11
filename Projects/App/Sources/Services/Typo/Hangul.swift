import Foundation

/// Hangul syllable arithmetic and 2-beolsik keystroke mapping.
enum Hangul {
    struct Jamo: Equatable {
        let initial: Int
        let medial: Int
        let final: Int
    }

    private static let syllableRange: ClosedRange<UInt32> = 0xAC00...0xD7A3
    private static let initialCount = 19
    private static let medialCount = 21
    private static let finalCount = 28

    static let initialKeys: [Int: Character] = [
        0: "r", 1: "R", 2: "s", 3: "e", 4: "E", 5: "f", 6: "a", 7: "q", 8: "Q", 9: "t",
        10: "T", 11: "d", 12: "w", 13: "W", 14: "c", 15: "z", 16: "x", 17: "v", 18: "g"
    ]

    static let medialKeys: [Int: Character] = [
        0: "k", 1: "o", 2: "i", 4: "j", 5: "p", 6: "u", 8: "h", 12: "y", 13: "n", 17: "b", 18: "m", 20: "l"
    ]

    static let finalKeys: [Int: Character] = [
        1: "r", 2: "R", 4: "s", 7: "e", 8: "f", 16: "a", 17: "q", 19: "t", 20: "T", 21: "d",
        22: "w", 23: "c", 24: "z", 25: "x", 26: "v", 27: "g"
    ]

    private static let initialIndexByKey = reversed(initialKeys)
    private static let medialIndexByKey = reversed(medialKeys)
    /// Reverse lookup of `finalKeys`; also answers "can this key be a final consonant".
    static let finalIndexByKey = reversed(finalKeys)

    private static func reversed(_ map: [Int: Character]) -> [Character: Int] {
        Dictionary(uniqueKeysWithValues: map.map { ($0.value, $0.key) })
    }

    static func isSyllable(_ character: Character) -> Bool {
        guard character.unicodeScalars.count == 1, let scalar = character.unicodeScalars.first else {
            return false
        }
        return syllableRange.contains(scalar.value)
    }

    static func decompose(_ character: Character) -> Jamo? {
        guard isSyllable(character), let scalar = character.unicodeScalars.first else {
            return nil
        }
        let offset = Int(scalar.value - syllableRange.lowerBound)
        let initial = offset / (medialCount * finalCount)
        let rest = offset % (medialCount * finalCount)
        return Jamo(initial: initial, medial: rest / finalCount, final: rest % finalCount)
    }

    static func compose(initial: Int, medial: Int, final: Int) -> Character? {
        guard (0..<initialCount).contains(initial),
              (0..<medialCount).contains(medial),
              (0..<finalCount).contains(final) else {
            return nil
        }
        let offset = (initial * medialCount * finalCount) + (medial * finalCount) + final
        guard let scalar = UnicodeScalar(syllableRange.lowerBound + UInt32(offset)) else {
            return nil
        }
        return Character(scalar)
    }

    /// 2-beolsik keystrokes (2 or 3 keys) that type `syllable`; nil for compound jamo not in the key maps.
    static func keystrokes(for syllable: Character) -> [Character]? {
        guard let jamo = decompose(syllable),
              let initialKey = initialKeys[jamo.initial],
              let medialKey = medialKeys[jamo.medial] else {
            return nil
        }

        var keys = [initialKey, medialKey]
        if jamo.final > 0 {
            guard let finalKey = finalKeys[jamo.final] else {
                return nil
            }
            keys.append(finalKey)
        }
        return keys
    }

    static func syllable(from keystrokes: [Character]) -> Character? {
        guard (2...3).contains(keystrokes.count),
              let initial = initialIndexByKey[keystrokes[0]],
              let medial = medialIndexByKey[keystrokes[1]] else {
            return nil
        }

        var final = 0
        if keystrokes.count == 3 {
            guard let mapped = finalIndexByKey[keystrokes[2]] else {
                return nil
            }
            final = mapped
        }
        return compose(initial: initial, medial: medial, final: final)
    }
}
