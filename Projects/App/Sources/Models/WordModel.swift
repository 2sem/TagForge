import Foundation
import SwiftData

@Model
final class WordModel {
    var text: String
    @Relationship var wordSet: WordSetModel? // Removed inverse parameter
    
    init(text: String, wordSet: WordSetModel? = nil) {
        self.text = text
        self.wordSet = wordSet
    }
}
