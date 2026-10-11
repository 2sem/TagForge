import Foundation

enum EditDistance {
    /// Bounded Damerau-Levenshtein (optimal string alignment) distance.
    /// Insertion, deletion, substitution and adjacent transposition each cost 1.
    /// Returns `limit + 1` as soon as the distance is known to exceed `limit`.
    static func damerauLevenshtein(_ lhs: [Character], _ rhs: [Character], limit: Int) -> Int {
        if lhs == rhs {
            return 0
        }
        if abs(lhs.count - rhs.count) > limit {
            return limit + 1
        }
        if lhs.isEmpty || rhs.isEmpty {
            return max(lhs.count, rhs.count)
        }

        var twoBack = [Int](repeating: 0, count: rhs.count + 1)
        var previous = Array(0...rhs.count)
        var current = [Int](repeating: 0, count: rhs.count + 1)

        for i in 1...lhs.count {
            current[0] = i
            var rowMinimum = current[0]

            for j in 1...rhs.count {
                let cost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
                var value = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                if i > 1, j > 1, lhs[i - 1] == rhs[j - 2], lhs[i - 2] == rhs[j - 1] {
                    value = min(value, twoBack[j - 2] + 1)
                }
                current[j] = value
                rowMinimum = min(rowMinimum, value)
            }

            if rowMinimum > limit {
                return limit + 1
            }
            (twoBack, previous, current) = (previous, current, twoBack)
        }

        return min(previous[rhs.count], limit + 1)
    }
}
