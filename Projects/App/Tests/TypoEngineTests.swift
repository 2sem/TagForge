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

    @Test("Seoul -> Soeul surfaces at low and medium intensity")
    func seoulSoeulSurfaces() {
        #expect(engine.variants(for: "Seoul", intensity: .low) == ["Soeul"])
        #expect(engine.variants(for: "Seoul", intensity: .medium).first == "Soeul")
    }

    @Test("Transposition outranks every keyboard substitution; omission outranks transposition", arguments: [
        "Seoul", "Swift", "Review", "iPhone17", "iPhone18", "Hello_World", "Coffee"
    ])
    func transpositionRanksAboveSubstitution(tag: String) throws {
        let ranked = engine.rankedCandidates(for: tag)
        let transpositions = ranked.filter { $0.rule == .adjacentTransposition && $0.score > 2.7 }
        let substitutions = ranked.filter { $0.rule == .keyboardNeighborSubstitution }
        let bestSubstitution = try #require(substitutions.map(\.score).max())

        #expect(!transpositions.isEmpty)
        #expect(transpositions.allSatisfy { $0.score > bestSubstitution })
        for omission in ranked where omission.rule == .repeatedLetterOmission {
            #expect(transpositions.allSatisfy { omission.score > $0.score })
        }
    }

    @Test("Latin transposition results for product-name tags", arguments: [
        ("iPhone17", "iPhoen17"), ("iPhone18", "iPhoen18"), ("Review", "Reivew"), ("Swift", "Siwft")
    ])
    func latinTranspositionTop(tag: String, expected: String) {
        #expect(engine.variants(for: tag, intensity: .low) == [expected])
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

    @Test("Korean missed final consonant: 카카오톡 -> 카카오토")
    func koreanMissedFinal() throws {
        let candidate = try #require(engine.rankedCandidates(for: "카카오톡").first { $0.value == "카카오토" })

        #expect(candidate.rule == .koreanMissedKeystroke)
    }

    @Test("Korean missed final: other realistic tags", arguments: [
        ("서울여행", "서우여행"), ("서울여행", "서울여해"), ("맛집투어", "마집투어"), ("커피한잔", "커피하잔"), ("대한민국", "대한민구")
    ])
    func koreanMissedFinalExamples(tag: String, expected: String) throws {
        let candidate = try #require(engine.rankedCandidates(for: tag).first { $0.value == expected })

        #expect(candidate.rule == .koreanMissedKeystroke)
    }

    @Test("Korean double press: repeated common initial becomes a final")
    func koreanDoublePress() throws {
        let candidate = try #require(engine.rankedCandidates(for: "소확행일상").first { $0.value == "솟확행일상" })

        #expect(candidate.rule == .koreanDoublePress)
    }

    @Test("Korean double press never produces rare finals or doubles the silent initial")
    func koreanDoublePressStaysCommon() {
        // ㅋ/ㄷ would give 캌/댇; ㅇ would give 잉/앙-style word changes.
        let kakao = engine.rankedCandidates(for: "카카오톡").map(\.value)
        #expect(!kakao.contains("캌카오톡"))
        #expect(!kakao.contains("카캌오톡"))
        #expect(!engine.rankedCandidates(for: "대한민국").map(\.value).contains("댇한민국"))
        #expect(!engine.rankedCandidates(for: "이야기여행").map(\.value).contains("잉야기여행"))
    }

    @Test("Korean adjacent-key substitution changes exactly one syllable")
    func koreanSubstitutionChangesOneSyllable() {
        let ranked = engine.rankedCandidates(for: "카카오톡")

        #expect(!ranked.isEmpty)
        for candidate in ranked {
            let diff = zip("카카오톡", candidate.value).filter { $0 != $1 }.count
            #expect(diff == 1)
        }
    }

    @Test("Korean-only outputs are unchanged by the missed-final / double-press additions", arguments: [
        ("카카오톡", ["카카오툑", "카카요톡"]),
        ("서울여행", ["서율여행"]),
        ("사랑해요", ["사렁해요", "서랑해요"]),
        ("대한민국", ["대한민귝", "대헌민국"]),
        ("먹스타그램", ["먹스타그랩", "먹스터그램"])
    ])
    func koreanSubstitutionOutputsUnchanged(tag: String, expectedSubstitutions: [String]) {
        let ranked = engine.rankedCandidates(for: tag)
        let substitutions = ranked.filter { $0.rule == .koreanAdjacentKeySubstitution }.map(\.value)

        #expect(Swift.Set(substitutions).isSuperset(of: expectedSubstitutions))
        // Substitutions rank first, and the intensity-capped output is the same as before.
        #expect(ranked.prefix(substitutions.count).allSatisfy { $0.rule == .koreanAdjacentKeySubstitution })
        #expect(engine.variants(for: tag, intensity: .low) == [expectedSubstitutions[0]])
    }

    @Test("Korean substitutions outrank missed-final and double-press candidates")
    func koreanSubstitutionOutranksNewRules() throws {
        let ranked = engine.rankedCandidates(for: "카카오톡")
        let missed = try #require(ranked.firstIndex { $0.value == "카카오토" })
        let lastSubstitution = try #require(ranked.lastIndex { $0.rule == .koreanAdjacentKeySubstitution })

        #expect(lastSubstitution < missed)
        #expect(engine.variants(for: "카카오톡", intensity: .medium) == ["카카오툑", "카카요톡"])
    }

    @Test("Mixed token: Korean-side and Latin results are stable at low intensity")
    func mixedTokenLowIntensity() {
        #expect(engine.variants(for: "맛집Review", intensity: .low) == ["맛짐Review"])
        #expect(engine.variants(for: "Seoul여행", intensity: .low) == ["Soeul여행"])
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
