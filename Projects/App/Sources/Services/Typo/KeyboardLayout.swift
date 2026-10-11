import Foundation

/// Physical QWERTY adjacency used by both the Latin and Korean (2-beolsik) typo rules.
enum KeyboardLayout {
    private static let rows: [[Character]] = [
        Array("qwertyuiop"),
        Array("asdfghjkl"),
        Array("zxcvbnm")
    ]

    /// Adjacent keys (lowercase) per key. Order is the legacy order used by the Korean rules.
    static let neighbors: [Character: [Character]] = [
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

    /// Neighbors of `key` with same-row (horizontal) keys first, preserving the legacy order within each group.
    /// Latin substitutions take a short prefix of this list so they favor same-line slips.
    static func horizontalFirstNeighbors(of key: Character) -> [Character]? {
        guard let all = neighbors[key], let row = rowIndex(of: key) else {
            return neighbors[key]
        }
        let sameRow = all.filter { rowIndex(of: $0) == row }
        let otherRows = all.filter { rowIndex(of: $0) != row }
        return sameRow + otherRows
    }

    private static func rowIndex(of key: Character) -> Int? {
        rows.firstIndex { $0.contains(key) }
    }
}
