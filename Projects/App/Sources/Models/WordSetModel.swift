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
    var name: String
    @Relationship var words: [String]
    var replaceSpaces: Bool
    var attachSharp: Bool
    var generateCombinations: Bool
    
    init(name: String, words: [String], replaceSpaces: Bool = false, attachSharp: Bool = false, generateCombinations: Bool = false) {
        self.name = name
        self.words = words
        self.replaceSpaces = replaceSpaces
        self.attachSharp = attachSharp
        self.generateCombinations = generateCombinations
    }
}
