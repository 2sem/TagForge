import SwiftUI

struct ContentView: View {
    @State private var inputText: String = "" // 입력받을 단어를 저장할 상태 변수
    @State private var wordList: [String] = [] // 등록된 단어 목록을 저장할 상태 변수
    @State private var generatedTags: String = "" // 생성된 태그를 저장할 상태 변수
    @State private var replaceSpacesWithUnderscore: Bool = false // 공백을 _로 치환할지 선택하는 상태 변수

    var body: some View {
        VStack {
            TextField("Enter a word...", text: $inputText) // 단어 입력 필드
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Add Word") {
                addWord() // 단어 추가 버튼
            }
            .padding()

            List {
                ForEach(wordList, id: \.self) { word in
                    Text(word) // 등록된 단어 표시
                }
                .onDelete(perform: deleteWords) // 스와이프하여 삭제 기능
            }
            .padding()

            Toggle("Replace spaces with _", isOn: $replaceSpacesWithUnderscore) // 체크박스 추가
                .padding()

            Button("Generate Tags") {
                generateTags() // 태그 생성 버튼
            }
            .padding()

            // 생성된 태그 표시
            Text(generatedTags) // 생성된 태그 표시
                .padding(5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .padding()
        }
        .padding()
    }

    private func addWord() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            wordList.append(trimmedText) // 입력된 단어를 목록에 추가
            inputText = "" // 입력 필드 초기화
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        wordList.remove(atOffsets: offsets) // 스와이프하여 삭제
    }

    private func generateTags() {
        if replaceSpacesWithUnderscore {
            generatedTags = wordList.map { $0.replacingOccurrences(of: " ", with: "_") }.joined(separator: ", ") // 공백을 _로 치환하여 태그 생성
        } else {
            generatedTags = wordList.joined(separator: ", ") // 단어들을 하나의 문자열로 결합
        }
    }
}

// 미리보기 추가
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 