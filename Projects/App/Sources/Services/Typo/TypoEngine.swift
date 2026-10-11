import Foundation

/// Deterministic, pure typo generator. Produces realistic keyboard-slip variants of a tag.
///
/// - Latin text: repeated-letter omission, same-row-first neighbor substitution, adjacent transposition.
/// - Korean text: 2-beolsik keystroke-level slips filtered for plausible compositions.
/// - Mixed Korean + Latin text: one segment mutated per candidate, Korean side preferred,
///   at most one Latin-side fallback.
///
/// Tags that contain only one script plus digits/symbols (`cafe1`, `Hello_World`) use the
/// single-script rules and are never routed through the mixed-script path.
struct TypoEngine {
    static let minimumTagLength = 4

    private static let mixedTokenBump = 0.6
    private static let koreanSideBump = 0.35
    private static let latinNeighborPenaltyWithKoreanCandidates = -1.2
    private static let latinNeighborPenaltyWithoutKoreanCandidates = -0.35
    private static let maxLatinSideFallbacks = 1

    private let latin = LatinTypoGenerator()
    private let korean = KoreanTypoGenerator()

    init() {}

    /// Up to `intensity.maxVariantsPerTag` variants, best first. Never contains `tag` itself.
    func variants(for tag: String, intensity: TypoVariantIntensity) -> [String] {
        var selected: [String] = []
        var latinFallbackCount = 0

        for candidate in rankedCandidates(for: tag) {
            guard selected.count < intensity.maxVariantsPerTag else {
                break
            }
            if candidate.isLatinSideFallback {
                guard latinFallbackCount < Self.maxLatinSideFallbacks else {
                    continue
                }
                latinFallbackCount += 1
            }
            selected.append(candidate.value)
        }
        return selected
    }

    /// All surviving candidates for `tag`, best first, before any intensity cap.
    func rankedCandidates(for tag: String) -> [TypoCandidate] {
        guard tag.count >= Self.minimumTagLength else {
            return []
        }

        let segments = TypoSegment.split(tag)
        let isMixed = segments.contains { $0.script == .korean } && segments.contains { $0.script == .latin }
        let hasKoreanSideCandidates = isMixed && segments.contains {
            $0.script == .korean && !korean.rankedCandidates(for: $0.text).isEmpty
        }

        var bestByValue: [String: TypoCandidate] = [:]

        for (index, segment) in segments.enumerated() {
            let segmentCandidates: [TypoCandidate]
            switch segment.script {
            case .korean:
                segmentCandidates = korean.rankedCandidates(for: segment.text)
            case .latin:
                segmentCandidates = latin.rankedCandidates(for: segment.text, isMixedToken: isMixed)
            case .other:
                continue
            }

            for segmentCandidate in segmentCandidates where segmentCandidate.value != segment.text {
                var rebuilt = segments.map(\.text)
                rebuilt[index] = segmentCandidate.value
                let value = rebuilt.joined()
                guard value != tag else {
                    continue
                }

                var score = segmentCandidate.score
                if isMixed {
                    score += Self.mixedTokenBump
                    score += mixedRankingAdjustment(for: segmentCandidate.rule, hasKoreanSideCandidates: hasKoreanSideCandidates)
                }

                bestByValue.insertKeepingBest(TypoCandidate(
                    value: value,
                    score: score,
                    rule: segmentCandidate.rule,
                    isLatinSideFallback: isMixed && segment.script == .latin
                ))
            }
        }

        return bestByValue.values.sortedByRank()
    }

    private func mixedRankingAdjustment(for rule: TypoCandidateRule, hasKoreanSideCandidates: Bool) -> Double {
        if rule.isKorean {
            return Self.koreanSideBump
        }
        if rule == .keyboardNeighborSubstitution {
            return hasKoreanSideCandidates
                ? Self.latinNeighborPenaltyWithKoreanCandidates
                : Self.latinNeighborPenaltyWithoutKoreanCandidates
        }
        return 0
    }
}

extension TypoVariantIntensity {
    /// Per-tag variant cap for this intensity.
    var maxVariantsPerTag: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        }
    }
}
