import Foundation
import SwiftData

@Model
final class WordModel {
    var text: String = "" // 기본값 추가
    @Relationship var wordSet: WordSetModel? // Removed inverse parameter
    
    init(text: String = "", wordSet: WordSetModel? = nil) { // 기본값 추가
        self.text = text
        self.wordSet = wordSet
    }
}
