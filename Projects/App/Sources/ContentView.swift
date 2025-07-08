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
                VStack(spacing: 0) {
                    HeaderView()
                    Divider().padding(.bottom, 8)
                    InputWordView()
                    TagChipListView()
                    OptionsView()
                    GenerateTagsView()
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .background(Color(red: 0.98, green: 0.98, blue: 0.98).ignoresSafeArea())
            }
        }
        .ignoresSafeArea(.keyboard)
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
        .overlay(
            Group {
                if showingCopiedAlert {
                    VStack {
                        Spacer()
                        Text("복사 완료!")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .padding(.bottom, 40)
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

    private func HeaderView() -> some View {
        HStack(spacing: 12) {
            Button(action: { /* 탭 선택 액션 */ }) {
                HStack(spacing: 8) {
                    Text(viewModel.currentWordSet.name.isEmpty ? "Default" : viewModel.currentWordSet.name)
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            Spacer()
            Button(action: { showingSetNameDialog = true }) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 20, weight: .medium))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            Button(action: { showingEditSetNameDialog = true }) {
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .medium))
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 12)
    }

    private func InputWordView() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "tag")
                .foregroundColor(.gray)
            TextField("태그를 입력하고 + 버튼을 눌러 추가하세요", text: $inputText)
                .font(.system(size: 16))
                .focused($isInputFocused)
                .onSubmit { addWord() }
            Button(action: addWord) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .padding(.bottom, 8)
    }

    private func TagChipListView() -> some View {
        let words = viewModel.currentWordSet.words ?? []
        return Group {
            if words.isEmpty {
                EmptyWordListView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(words, id: \.text) { word in
                            HStack(spacing: 4) {
                                Image(systemName: "line.horizontal.3")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(word.text)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Button(action: { viewModel.deleteWord(word) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(red: 0.91, green: 0.30, blue: 0.24))
                                        .padding(.leading, 2)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.29, green: 0.56, blue: 0.89))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func OptionsView() -> some View {
        HStack(spacing: 12) {
            OptionButton(isSelected: viewModel.currentWordSet.replaceSpaces, text: "공백을 _로 대체") {
                viewModel.currentWordSet.replaceSpaces.toggle()
            }
            OptionButton(isSelected: viewModel.currentWordSet.attachSharp, text: "# 추가") {
                viewModel.currentWordSet.attachSharp.toggle()
            }
            OptionButton(isSelected: viewModel.currentWordSet.generateCombinations, text: "조합 생성") {
                viewModel.currentWordSet.generateCombinations.toggle()
            }
        }
        .padding(.vertical, 8)
    }

    private func GenerateTagsView() -> some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.generateTags()
                }
                isInputFocused = false
            }) {
                Text("태그 만들기")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.35, green: 0.40, blue: 0.95))
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            if !viewModel.generatedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("생성된 태그")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = viewModel.generatedTags
                            showingCopiedAlert = true
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                    }
                    Text(viewModel.generatedTags)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                HStack(spacing: 16) {
                    Button(action: {
                        UIPasteboard.general.string = viewModel.generatedTags
                        showingCopiedAlert = true
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.18), radius: 4, x: 0, y: 2)
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
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.18), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }

    private func EmptyWordListView() -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "tag")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.6))
                Text("태그를 추가해보세요.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func addWord() {
        withAnimation {
            if !viewModel.addWord(inputText) && !inputText.isEmpty {
                duplicateWord = inputText
                showingDuplicateAlert = true
            }
            inputText = ""
        }
    }
}

struct OptionButton: View {
    let isSelected: Bool
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isSyncing: .constant(false))
    }
}
