import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showingSetNameDialog = false
    @State private var showingDuplicateAlert = false
    @State private var showingCopiedAlert = false
    @State private var newSetName: String = ""
    @State private var duplicateWord: String = ""
    @State private var clipboardWords: [String] = []
    
    var body: some View {
        ZStack {
            if viewModel.isSyncing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Synchronizing ...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                VStack {
                    HeaderView()
                    InputWordView()
                    WordListView()
                    OptionsView()
                    GenerateTagsView()
                }
            }
        }
        .onAppear{
//            viewModel.loadWordSets()
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
                viewModel.createNewSet(name: newSetName)
                newSetName = ""
            }
        }
        .padding()
    }
    
    private func HeaderView() -> some View {
        HStack {
            WordSetMenu(
                availableSets: viewModel.wordSets,
                onSelectWordSet: { viewModel.loadWord(set: $0) }
            ) {
                HStack {
                    Image(systemName: "chevron.down")
                    Text(viewModel.currentWordSet.name.isEmpty ? "Default" : viewModel.currentWordSet.name)
                }
            }
            Spacer()
            Button(action: { showingSetNameDialog = true }) {
                Image(systemName: "doc.badge.plus")
            }
        }.padding()
    }
    
    private func InputWordView() -> some View {
        HStack {
            TextField("Enter a word...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isInputFocused)
                .onSubmit {
                    addWord()
                    isInputFocused = true
                }
                .submitLabel(.send)
            Button(action: addWord) {
                Image(systemName: "plus")
            }
        }
    }
    
    private func WordListView() -> some View {
        Group {
            if viewModel.currentWordSet.words?.isEmpty ?? true {
                EmptyWordListView()
            } else {
                List {
                    ForEach(viewModel.currentWordSet.words ?? [], id: \.text) { word in
                        HStack {
                            Text(word.text)
                            Spacer()
                            Button(action: { viewModel.deleteWord(word) }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteWords)
                }
                .padding()
            }
        }
    }
    
    private func OptionsView() -> some View {
        HStack {
            HStack {
                Image(systemName: viewModel.currentWordSet.replaceSpaces ? "checkmark.square" : "square")
                Text("Space to _")
            }
            .onTapGesture {
                viewModel.currentWordSet.replaceSpaces.toggle()
            }
            HStack {
                Image(systemName: viewModel.currentWordSet.attachSharp ? "checkmark.square" : "square")
                Text("#")
            }
            .onTapGesture {
                viewModel.currentWordSet.attachSharp.toggle()
                if viewModel.currentWordSet.attachSharp {
                    viewModel.currentWordSet.replaceSpaces = true
                }
            }
            HStack {
                Image(systemName: viewModel.currentWordSet.generateCombinations ? "checkmark.square" : "square")
                Text("Combinations")
            }
            .onTapGesture {
                viewModel.currentWordSet.generateCombinations.toggle()
            }
            Spacer()
        }
        .padding()
    }
    
    private func GenerateTagsView() -> some View {
        VStack {
            Button("Generate Tags") {
                viewModel.generateTags()
            }
            .padding()
            if !viewModel.generatedTags.isEmpty {
                HStack {
                    Text(viewModel.generatedTags)
                        .padding(5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .onLongPressGesture {
                            UIPasteboard.general.string = viewModel.generatedTags
                            showingCopiedAlert = true
                        }
                    Button(action: {
                        UIPasteboard.general.string = viewModel.generatedTags
                        showingCopiedAlert = true
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 8)
                    Button(action: {
                        let activityVC = UIActivityViewController(activityItems: [viewModel.generatedTags], applicationActivities: nil)
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
                    .disabled(viewModel.generatedTags.isEmpty)
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
    }
    
    private func EmptyWordListView() -> some View {
        VStack(spacing: 16) {
            Text("No words in the current set.\nAdd words.")
                .foregroundColor(.gray)
                .italic()
                .multilineTextAlignment(.center)
            
            if viewModel.wordSets.count > 1 {
                WordSetMenu(availableSets: viewModel.wordSets,
                            onSelectWordSet: { set in
                    viewModel.loadWord(set: set)
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Select existing set")
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func addWord() {
        if !viewModel.addWord(inputText) && !inputText.isEmpty {
            duplicateWord = inputText
            showingDuplicateAlert = true
        }
        inputText = ""
    }
    
    // Keeping clipboard-related functions unchanged
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
                if !viewModel.currentWordSet.replaceSpaces {
                    processed = processed.replacingOccurrences(of: "_", with: " ")
                }
                return processed
            }
            .filter { !$0.isEmpty }
        
        return words
    }
    
    private func importClipboardWords() {
        for word in clipboardWords {
            let isAlreadyExistingWord = viewModel.currentWordSet.words?.contains(where: { $0.text == word }) ?? false
            
            guard isAlreadyExistingWord else {
                continue
            }
            
            viewModel.currentWordSet.words?.append(.init(text: word))
        }
        clipboardWords.removeAll()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
