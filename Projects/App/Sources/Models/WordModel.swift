import SwiftData

@Model
final class WordModel {
    var text: String = "" // 기본값 추가
    var order: Int = 0 // 순서 정보 추가
    @Relationship var wordSet: WordSetModel? // Removed inverse parameter

    init(text: String = "", order: Int = 0, wordSet: WordSetModel? = nil) { // order 파라미터 추가
        self.text = text
        self.order = order
        self.wordSet = wordSet
    }
}
