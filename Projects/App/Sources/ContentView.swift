import SwiftUI
import SwiftData
import UIKit

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
    @State private var isGenerating: Bool = false

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
        HStack(spacing: 0) {
            TextField("Enter a tag and tap + to add", text: $inputText)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .focused($isInputFocused)
                .onSubmit { addWord() }
                .background(Color.white)
            Button(action: addWord) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isInputFocused ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .padding(.bottom, 8)
    }

private func TagChipListView() -> some View {
        let words = (viewModel.currentWordSet.words ?? []).sorted { $0.order < $1.order }
        let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return Group {
            if words.isEmpty {
                EmptyWordListView()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(words, id: \.id) { word in
                            HStack(spacing: 8) {
                                Text(word.text)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Button(action: { viewModel.deleteWord(word) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.red.opacity(0.85))
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 2)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color(red: 0.29, green: 0.56, blue: 0.89))
                            .cornerRadius(18)
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
        HStack(spacing: 8) {
            OptionButton(isSelected: viewModel.currentWordSet.replaceSpaces, icon: "arrow.right.to.line", text: "공백을 _로 대체") {
                viewModel.currentWordSet.replaceSpaces.toggle()
            }
            OptionButton(isSelected: viewModel.currentWordSet.attachSharp, icon: "number", text: "# 추가") {
                viewModel.currentWordSet.attachSharp.toggle()
            }
            OptionButton(isSelected: viewModel.currentWordSet.generateCombinations, icon: "square.stack.3d.up", text: "조합 생성") {
                viewModel.currentWordSet.generateCombinations.toggle()
            }
        }
        .padding(.vertical, 8)
    }

    private func GenerateTagsView() -> some View {
        VStack(spacing: 12) {
            Button(action: {
                isGenerating = true
                withAnimation(.spring()) {
                    viewModel.generateTags()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    isGenerating = false
                }
                isInputFocused = false
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.35, green: 0.40, blue: 0.95))
                        .shadow(color: .blue.opacity(0.18), radius: 8, x: 0, y: 4)
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("태그 만들기")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 56)
                .scaleEffect(isGenerating ? 0.97 : 1.0)
                .animation(.spring(), value: isGenerating)
            }
            .buttonStyle(PlainButtonStyle())
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
                            withAnimation {
                                showingCopiedAlert = true
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                    }
                    ScrollView(.vertical) {
                        Text(viewModel.generatedTags)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(12)
                    }
                    .frame(maxHeight: 120)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                HStack(spacing: 16) {
                    Button(action: {
                        UIPasteboard.general.string = viewModel.generatedTags
                        withAnimation {
                            showingCopiedAlert = true
                        }
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
                        withAnimation {
                            showingCopiedAlert = true
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
    let icon: String
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .cornerRadius(16)
            .shadow(color: isSelected ? Color.blue.opacity(0.12) : .clear, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isSyncing: .constant(false))
    }
}
