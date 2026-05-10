//
//  WordSetModel.swift
//  App
//
//  Created by 영준 이 on 2/2/25.
//

import Foundation
import SwiftData

enum TypoVariantIntensity: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
}

@Model
final class WordSetModel {
    var name: String = "" // 기본값 추가
    @Relationship(deleteRule: .cascade, inverse: \WordModel.wordSet) var words: [WordModel]? // ...existing code...
    var attachSharp: Bool = false // 기본값 추가
    var generateCombinations: Bool = false // 기본값 추가
    var maxCombinationLength: Int = 2
    var includeTypoVariants: Bool = false
    var typoVariantIntensityRawValue: Int = TypoVariantIntensity.low.rawValue

    var typoVariantIntensity: TypoVariantIntensity {
        get { TypoVariantIntensity(rawValue: typoVariantIntensityRawValue) ?? .low }
        set { typoVariantIntensityRawValue = newValue.rawValue }
    }

    init(
        name: String = "",
        words: [WordModel] = [],
        attachSharp: Bool = false,
        generateCombinations: Bool = false,
        maxCombinationLength: Int = 2,
        includeTypoVariants: Bool = false,
        typoVariantIntensity: TypoVariantIntensity = .low
    ) { // 기본값 추가
        self.name = name
        self.words = words
        self.attachSharp = attachSharp
        self.generateCombinations = generateCombinations
        self.maxCombinationLength = maxCombinationLength
        self.includeTypoVariants = includeTypoVariants
        self.typoVariantIntensityRawValue = typoVariantIntensity.rawValue
    }
}
