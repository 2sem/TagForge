import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var wordList: [String] = []
    @State private var generatedTags: String = ""
    @State private var replaceSpacesWithUnderscore: Bool = false
    @State private var attachSharpTag: Bool = false
    @State private var generateCombinations: Bool = false
    @State private var showingCopiedAlert = false

    @State private var clipboardWords: [String] = []
    
    @State private var currentSetName: String = ""
    @State private var showingSetNameDialog = false
    @State private var newSetName: String = ""
    @State private var availableSets: [WordSet] = []
    
    private func saveCurrentSet() {
        guard !currentSetName.isEmpty else { return }
        
        let settings = WordSet.Settings(
            replaceSpaces: replaceSpacesWithUnderscore,
            attachSharp: attachSharpTag,
            generateCombinations: generateCombinations
        )
        
        TagStorageManager.shared.saveWordSet(
            name: currentSetName,
            words: wordList,
            settings: settings
        )
    }
    
    private func loadSet(named name: String) {
        guard let set = TagStorageManager.shared.getWordSet(named: name) else { return }
        
        currentSetName = set.name
        wordList = set.words
        replaceSpacesWithUnderscore = set.settings.replaceSpaces
        attachSharpTag = set.settings.attachSharp
        generateCombinations = set.settings.generateCombinations
        
        TagStorageManager.shared.setCurrentSet(name: name)
    }
    
    private func loadAvailableSets() {
        availableSets = TagStorageManager.shared.getAllWordSets()
    }
    
    var body: some View {
        VStack {
            // Add set selection menu
            HStack {
                Menu {
                    ForEach(availableSets, id: \.name) { set in
                        Button(set.name) {
                            loadSet(named: set.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(currentSetName.isEmpty ? "Select Set" : currentSetName)
                        Image(systemName: "chevron.down")
                    }
                }
                
                Button("New Set") {
                    showingSetNameDialog = true
                }
            }
            .padding()
            
            TextField("Enter a word...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Add Word") {
                addWord()
            }
            .padding()
            
            if wordList.isEmpty, !availableSets.isEmpty {
                VStack(spacing: 16) {
                    Text("No words in the current set")
                        .foregroundColor(.gray)
                        .italic()
                    
                    Menu {
                        if availableSets.isEmpty {
                            Text("No saved sets")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(availableSets, id: \.name) { set in
                                Button(set.name) {
                                    loadSet(named: set.name)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("Select existing set")
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showingSetNameDialog = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create new set")
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
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
            }
            
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
            
            if !generatedTags.isEmpty {
                HStack {
                    Text(generatedTags)
                        .padding(5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .onLongPressGesture {
                            UIPasteboard.general.string = generatedTags
                            showingCopiedAlert = true
                        }
                    
                    Button(action: {
                        UIPasteboard.general.string = generatedTags
                        showingCopiedAlert = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 8)
                    
                    Button(action: {
                        let activityVC = UIActivityViewController(activityItems: [generatedTags], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            activityVC.popoverPresentationController?.sourceView = rootVC.view
                            rootVC.present(activityVC, animated: true)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .disabled(generatedTags.isEmpty)
                }
                .padding()
                .overlay(
                    Group {
                        if showingCopiedAlert {
                            VStack {
                                Spacer()
                                Text("Tags copied!")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.75))
                                    .cornerRadius(10)
                                    .transition(.move(edge: .bottom))
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showingCopiedAlert = false
                                        }
                                    }
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            loadAvailableSets()
            if let currentName = TagStorageManager.shared.getCurrentSetName() {
                loadSet(named: currentName)
            }
        }
        .alert("Duplicate Word", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("'\(duplicateWord)' is already in the list")
        }
        .alert("New Set Name", isPresented: $showingSetNameDialog) {
            TextField("Set Name", text: $newSetName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                currentSetName = newSetName
                wordList = []
                saveCurrentSet()
                loadAvailableSets()
                newSetName = ""
            }
        }
        .onChange(of: wordList) { _ in
            saveCurrentSet()
        }
        .onChange(of: replaceSpacesWithUnderscore) { _ in
            saveCurrentSet()
        }
        .onChange(of: attachSharpTag) { _ in
            saveCurrentSet()
        }
        .onChange(of: generateCombinations) { _ in
            saveCurrentSet()
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
    
    private func checkClipboard() {
        guard let clipboardText = UIPasteboard.general.string else { return }
        let parsedWords = parseClipboardText(clipboardText)
        
        guard !parsedWords.isEmpty else {
            return
        }
        
        clipboardWords = parsedWords
        
        importClipboardWords()
    }
    
    private func parseClipboardText(_ text: String) -> [String] {
        // Split by common separators (comma, space, newline)
        let words = text.components(separatedBy: CharacterSet(charactersIn: ", \n"))
            .map { word -> String in
                var processed = word.trimmingCharacters(in: .whitespacesAndNewlines)
                // Remove # if present
                if processed.hasPrefix("#") {
                    processed = String(processed.dropFirst())
                }
                // Replace underscores with spaces if needed
                if !replaceSpacesWithUnderscore {
                    processed = processed.replacingOccurrences(of: "_", with: " ")
                }
                return processed
            }
            .filter { !$0.isEmpty }
        
        return words
    }
    
    private func importClipboardWords() {
        for word in clipboardWords {
            if !wordList.contains(word) {
                wordList.append(word)
            }
        }
        clipboardWords.removeAll()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
