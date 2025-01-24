import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var wordList: [String] = []
    @State private var generatedTags: String = ""
    @State private var replaceSpacesWithUnderscore: Bool = false
    @State private var attachSharpTag: Bool = false

    var body: some View {
        VStack {
            TextField("Enter a word...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Add Word") {
                addWord()
            }
            .padding()

            List {
                ForEach(wordList, id: \.self) { word in
                    Text(word)
                }
                .onDelete(perform: deleteWords)
            }
                .padding()

            HStack {
                HStack {
                    Image(systemName: replaceSpacesWithUnderscore ? "checkmark.square" : "square")
                    Text("Replace spaces with _")
                }
                .onTapGesture {
                    replaceSpacesWithUnderscore.toggle()
                }
                Spacer()
                HStack {
                    Image(systemName: attachSharpTag ? "checkmark.square" : "square")
                    Text("Sharp Tag")
                }
                .onTapGesture {
                    attachSharpTag.toggle()
                }
            }
            .padding()

            Button("Generate Tags") {
                generateTags()
        }
        .padding()

            Text(generatedTags)
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
            wordList.append(trimmedText)
            inputText = ""
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        wordList.remove(atOffsets: offsets)
    }

    private func generateTags() {
        var tags = wordList.map { word in
            var tag = word
            if replaceSpacesWithUnderscore {
                tag = tag.replacingOccurrences(of: " ", with: "_")
            }
            if attachSharpTag {
                tag = "#" + tag
            }
            return tag
        }
        generatedTags = tags.joined(separator: ", ")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 