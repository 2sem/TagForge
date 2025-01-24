import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var wordList: [String] = []
    @State private var generatedTags: String = ""
    @State private var replaceSpacesWithUnderscore: Bool = false
    @State private var attachSharpTag: Bool = false
    @State private var generateCombinations: Bool = false
    
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
                    HStack {
                        Text(word)
                        Spacer()
                        Button(action: {
                            deleteWord(word: word)
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onDelete(perform: deleteWords)
            }
            .padding()
            
            HStack {
                HStack {
                    Image(systemName: replaceSpacesWithUnderscore ? "checkmark.square" : "square")
                    Text("Space to _")
                }
                .onTapGesture {
                    replaceSpacesWithUnderscore.toggle()
                }
                HStack {
                    Image(systemName: attachSharpTag ? "checkmark.square" : "square")
                    Text("#")
                }
                .onTapGesture {
                    attachSharpTag.toggle()
                    if attachSharpTag {
                        replaceSpacesWithUnderscore = true
                    }
                }
                
                HStack {
                    Image(systemName: generateCombinations ? "checkmark.square" : "square")
                    Text("Combinations")
                }
                .onTapGesture {
                    generateCombinations.toggle()
                }
                
                Spacer()
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
        .alert("Duplicate Word", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("'\(duplicateWord)' is already in the list")
        }
        .padding()
    }
    
    @State private var showingDuplicateAlert = false
    @State private var duplicateWord = ""
    
    private func addWord() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return
        }
        guard !wordList.contains(trimmedText) else {
            duplicateWord = trimmedText
            showingDuplicateAlert = true
            return
        }
        
        if !wordList.contains(trimmedText) {
            wordList.append(trimmedText)
            inputText = ""
        }
    }
    
    private func deleteWords(at offsets: IndexSet) {
        wordList.remove(atOffsets: offsets)
    }
    
    private func deleteWord(word: String) {
        if let index = wordList.firstIndex(where: { $0 == word }) {
            wordList.remove(at: index)
        }
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
        
        if generateCombinations {
            let combinations = generateCombinations(of: tags)
            tags.append(contentsOf: combinations)
        }
        
        generatedTags = tags.joined(separator: ", ")
    }
    
    private func generateCombinations(of words: [String]) -> [String] {
        var combinations = [String]()
        
        for length in 2...words.count {
            for combination in words.combinations(ofLength: length) {
                combinations.append(combination.joined())
            }
        }
        
        return combinations
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
