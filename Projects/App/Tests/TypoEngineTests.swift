import Testing
@testable import App

@Suite("TypoEngine")
struct TypoEngineTests {
    private let engine = TypoEngine()

    // MARK: - Ported from the prototype comparison harness (adapted to the shipping engine)

    @Test("Mixed token: suppresses implausible Latin vowel drift")
    func mixedTokenSuppressesLatinVowelDrift() {
        let all = engine.rankedCandidates(for: "Seoul여행").map(\.value)

        #expect(!all.contains("Seiul여행"))
    }

    @Test("Mixed token: keeps plausible Korean-side typo candidates")
    func mixedTokenKeepsPlausibleKoreanTypos() {
        let variants = engine.variants(for: "맛집Review", intensity: .medium)

        #expect(variants.contains("맛짐Review"))
        #expect(variants.allSatisfy { $0.hasSuffix("Review") || $0.hasPrefix("맛집") })
    }

    @Test("Korean-only token: keeps plausible typo candidates")
    func koreanOnlyKeepsPlausibleTypos() {
        let variants = engine.variants(for: "서울여행", intensity: .medium)

        #expect(variants.contains("서율여행"))
        #expect(variants.allSatisfy { $0.allSatisfy(Hangul.isSyllable) })
    }

    @Test("Mixed token: Korean-side typo ranks above Latin neighbor typo")
    func mixedTokenPrefersKoreanSideOverLatinNeighbor() throws {
        let ranked = engine.rankedCandidates(for: "맛집Review")
        let koreanIndex = try #require(ranked.firstIndex { $0.value == "맛짐Review" })

        let latinNeighbors = ranked.enumerated().filter {
            $0.element.rule == .keyboardNeighborSubstitution
        }
        #expect(!latinNeighbors.isEmpty)
        for (latinIndex, _) in latinNeighbors {
            #expect(koreanIndex < latinIndex)
        }
    }

    // MARK: - Latin rules

    @Test("Repeated-letter omission: Coffee -> Cofee")
    func repeatedLetterOmission() {
        #expect(engine.variants(for: "Coffee", intensity: .low) == ["Cofee"])
        #expect(engine.rankedCandidates(for: "Coffee").first?.rule == .repeatedLetterOmission)
    }

    @Test("Adjacent transposition: Seoul -> Soeul is generated")
    func adjacentTransposition() throws {
        let candidate = try #require(engine.rankedCandidates(for: "Seoul").first { $0.value == "Soeul" })

        #expect(candidate.rule == .adjacentTransposition)
    }

    @Test("Latin substitution favors same-row neighbors")
    func latinSubstitutionIsHorizontalFirst() {
        let values = engine.rankedCandidates(for: "Seoul").map(\.value)

        // 'o' neighbors: i/p are same row; k/l are a row below and must not be preferred.
        #expect(values.contains("Seiul"))
        #expect(values.contains("Sepul"))
        #expect(!values.contains("Sekul"))
    }

    @Test("Keyboard layout lists same-row neighbors before other rows")
    func horizontalFirstOrdering() {
        #expect(KeyboardLayout.horizontalFirstNeighbors(of: "o")?.prefix(2) == ["i", "p"])
        #expect(KeyboardLayout.horizontalFirstNeighbors(of: "d")?.prefix(2) == ["s", "f"])
    }

    // MARK: - Korean rules

    @Test("Korean missed final consonant (known gap: allow-list rejects final -> none)")
    func koreanMissedFinal() {
        // The doc lists "missed final consonant" as a keep-class, but KoreanTypoGenerator's
        // final-transition allow-list has no `x -> 0` entries, so the candidate is generated and
        // then filtered out. Flip this to a plain #expect once the allow-list is extended.
        withKnownIssue("missed-final candidates are rejected by the final-transition allow-list") {
            let values = engine.rankedCandidates(for: "카카오톡").map(\.value)
            #expect(values.contains("카카오토"))
        }
    }

    @Test("Korean adjacent-key substitution changes exactly one syllable")
    func koreanSubstitutionChangesOneSyllable() {
        let ranked = engine.rankedCandidates(for: "카카오톡")

        #expect(!ranked.isEmpty)
        for candidate in ranked {
            let diff = zip("카카오톡", candidate.value).filter { $0 != $1 }.count
            #expect(diff == 1)
            #expect(candidate.rule == .koreanAdjacentKeySubstitution)
        }
    }

    // MARK: - Intensity, determinism, boundaries

    @Test("Intensity caps: low = 1, medium = 2")
    func intensityCaps() {
        #expect(engine.variants(for: "Seoul", intensity: .low).count == 1)
        #expect(engine.variants(for: "Seoul", intensity: .medium).count == 2)
        #expect(TypoVariantIntensity.low.maxVariantsPerTag == 1)
        #expect(TypoVariantIntensity.medium.maxVariantsPerTag == 2)
    }

    @Test("Same input yields identical output")
    func deterministic() {
        let tags = ["Seoul", "Coffee", "서울여행", "카카오톡", "맛집Review", "Seoul여행"]
        for tag in tags {
            for intensity in TypoVariantIntensity.allCases {
                #expect(engine.variants(for: tag, intensity: intensity) == engine.variants(for: tag, intensity: intensity))
            }
        }
    }

    @Test("Empty and very short tags return no variants", arguments: ["", "a", "ab", "abc", "한글"])
    func shortTagsReturnNothing(tag: String) {
        #expect(engine.variants(for: tag, intensity: .medium).isEmpty)
    }

    @Test("Output never contains the input and never repeats", arguments: [
        "Seoul", "Coffee", "Mississippi", "서울여행", "카카오톡", "맛집Review", "Seoul여행", "cafe1", "Hello_World", "#Seoul"
    ])
    func outputNeverEqualsInput(tag: String) {
        let variants = engine.variants(for: tag, intensity: .medium)

        #expect(!variants.contains(tag))
        #expect(Swift.Set(variants).count == variants.count)
    }

    // MARK: - Latin + digits/symbols must not use the mixed-script path

    @Test("Latin + digit tag uses plain Latin scoring, not the mixed bump")
    func latinWithDigitIsNotMixed() throws {
        let ranked = engine.rankedCandidates(for: "cafe1")
        let top = try #require(ranked.first)

        #expect(top.rule == .keyboardNeighborSubstitution)
        #expect(top.score == 2.7)
        #expect(ranked.allSatisfy { !$0.isLatinSideFallback })
        #expect(ranked.allSatisfy { $0.value.hasSuffix("1") })
    }

    @Test("Latin + underscore tag uses plain Latin scoring")
    func latinWithUnderscoreIsNotMixed() throws {
        let top = try #require(engine.rankedCandidates(for: "Hello_World").first)

        #expect(top.value == "Helo_World")
        #expect(top.score == 5.0)
        #expect(!top.isLatinSideFallback)
        #expect(engine.rankedCandidates(for: "a_b").isEmpty)
    }

    @Test("Only tags with both Korean and Latin segments take the mixed path")
    func mixedPathRequiresBothScripts() throws {
        let mixedTop = try #require(engine.rankedCandidates(for: "맛집Review").first)
        let koreanWithSymbol = try #require(engine.rankedCandidates(for: "맛집_2").first)

        // Mixed bump (+0.6) and Korean-side bonus (+0.35) apply only to the Korean + Latin tag.
        #expect(mixedTop.score > koreanWithSymbol.score)
        #expect(koreanWithSymbol.score == 3.5)
        #expect(koreanWithSymbol.value.hasSuffix("_2"))
    }

    // MARK: - Edit distance

    @Test("Bounded Damerau-Levenshtein distance")
    func editDistance() {
        func d(_ a: String, _ b: String, limit: Int = 2) -> Int {
            EditDistance.damerauLevenshtein(Array(a), Array(b), limit: limit)
        }

        #expect(d("Seoul", "Seoul") == 0)
        #expect(d("Seoul", "Soeul") == 1)
        #expect(d("Coffee", "Cofee") == 1)
        #expect(d("Seoul", "Sekul") == 1)
        #expect(d("abcd", "badc") == 2)
        #expect(d("abcd", "wxyz") == 3)
        #expect(d("abcdef", "ab") == 3)
    }
}
