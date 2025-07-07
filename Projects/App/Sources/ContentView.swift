import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var isSyncing: Bool
    @StateObject private var viewModel = MainViewModel()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showingSetNameDialog = false
    @State private var showingDuplicateAlert = false
    @State private var showingCopiedAlert = false
    @State private var newSetName: String = ""
    @State private var duplicateWord: String = ""
    @State private var clipboardWords: [String] = []
    @State private var showingEditSetNameDialog = false
    @State private var editedSetName: String = ""

    var body: some View {
        ZStack {
            if viewModel.isSyncing {
                Text("Synchronizing ...")
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
        .onChange(of: viewModel.isSyncing) { newValue in
            isSyncing = newValue
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
        .alert("Edit Set Name", isPresented: $showingEditSetNameDialog) {
            TextField("Set Name", text: $editedSetName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                viewModel.renameCurrentSet(to: editedSetName)
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
            Button(action: {
                editedSetName = viewModel.currentWordSet.name
                showingEditSetNameDialog = true
            }) {
                Image(systemName: "pencil")
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
        HStack(spacing: 16) {
            // Space to _ 토글
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.currentWordSet.replaceSpaces.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.currentWordSet.replaceSpaces ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.currentWordSet.replaceSpaces ? .green : .gray)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Space to _")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.currentWordSet.replaceSpaces ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentWordSet.replaceSpaces ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.currentWordSet.replaceSpaces ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            // # 토글
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.currentWordSet.attachSharp.toggle()
                    if viewModel.currentWordSet.attachSharp {
                        viewModel.currentWordSet.replaceSpaces = true
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.currentWordSet.attachSharp ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.currentWordSet.attachSharp ? .blue : .gray)
                        .font(.system(size: 16, weight: .semibold))
                    Text("#")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(viewModel.currentWordSet.attachSharp ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentWordSet.attachSharp ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.currentWordSet.attachSharp ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            // Combinations 토글
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.currentWordSet.generateCombinations.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.currentWordSet.generateCombinations ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.currentWordSet.generateCombinations ? .purple : .gray)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Combinations")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.currentWordSet.generateCombinations ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentWordSet.generateCombinations ? Color.purple.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.currentWordSet.generateCombinations ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func GenerateTagsView() -> some View {
        VStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.generateTags()
                }
                isInputFocused = false // 태그 생성 시 키보드 내리기
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generate Tags")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(viewModel.generatedTags.isEmpty ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: viewModel.generatedTags.isEmpty)
            .padding()
            if !viewModel.generatedTags.isEmpty {
                VStack(spacing: 16) {
                    // 태그 결과 카드
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generated Tags")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        Text(viewModel.generatedTags)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                            .onLongPressGesture {
                                UIPasteboard.general.string = viewModel.generatedTags
                                showingCopiedAlert = true
                            }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    
                    // 액션 버튼들
                    HStack(spacing: 12) {
                        Button(action: {
                            UIPasteboard.general.string = viewModel.generatedTags
                            showingCopiedAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Copy")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            let activityVC = UIActivityViewController(activityItems: [viewModel.generatedTags], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                activityVC.popoverPresentationController?.sourceView = rootVC.view
                                rootVC.present(activityVC, animated: true)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Share")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
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
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "tag")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("No words in the current set.\nAdd words.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            if viewModel.wordSets.count > 1 {
                WordSetMenu(availableSets: viewModel.wordSets,
                            onSelectWordSet: { set in
                    viewModel.loadWord(set: set)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Select existing set")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
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
        ContentView(isSyncing: .constant(false))
    }
}
