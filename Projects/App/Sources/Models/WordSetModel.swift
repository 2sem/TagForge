//
//  WordSetModel.swift
//  App
//
//  Created by 영준 이 on 2/2/25.
//

import Foundation
import SwiftData

@Model
final class WordSetModel {
    var name: String = "" // 기본값 추가
    @Relationship(deleteRule: .cascade, inverse: \WordModel.wordSet) var words: [WordModel]? // ...existing code...
    var replaceSpaces: Bool = false // 기본값 추가
    var attachSharp: Bool = false // 기본값 추가
    var generateCombinations: Bool = false // 기본값 추가
    var maxCombinationLength: Int = 2
    var characterLimit: Int? = nil
    var platformPreset: String? = nil // raw value of PlatformPreset

    init(
        name: String = "",
        words: [WordModel] = [],
        replaceSpaces: Bool = false,
        attachSharp: Bool = false,
        generateCombinations: Bool = false,
        maxCombinationLength: Int = 2,
        characterLimit: Int? = nil,
        platformPreset: String? = nil
    ) { // 기본값 추가
        self.name = name
        self.words = words
        self.replaceSpaces = replaceSpaces
        self.attachSharp = attachSharp
        self.generateCombinations = generateCombinations
        self.maxCombinationLength = maxCombinationLength
        self.characterLimit = characterLimit
        self.platformPreset = platformPreset
    }
}
