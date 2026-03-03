import SwiftUI
import SwiftData
import UIKit
import OSLog

private let contentViewLogger = Logger(subsystem: "com.toyboy2.tagforge", category: "ContentView")

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
    @State private var showingWordSetPicker = false
    @State private var showingBatchImportAlert = false
    @State private var batchImportAdded: Int = 0
    @State private var batchImportSkipped: Int = 0

    var body: some View {
        ZStack {
            // 빈 공간 탭 시 키보드 닫힘
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
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
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
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
        .alert("Words Added", isPresented: $showingBatchImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if batchImportSkipped > 0 {
                Text("\(batchImportAdded) words added, \(batchImportSkipped) duplicates skipped")
            } else {
                Text("\(batchImportAdded) words added")
            }
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
        .sheet(isPresented: $showingWordSetPicker) {
            WordSetPickerView(viewModel: viewModel, isPresented: $showingWordSetPicker)
        }
        .overlay(
            Group {
                if showingCopiedAlert {
                    VStack {
                        Spacer()
                        Text("Copied!")
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
            Button(action: { showingWordSetPicker = true }) {
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
            .accessibilityLabel("New Set Name")
            Button(action: { showingEditSetNameDialog = true }) {
                Image(systemName: "pencil")
                    .font(.system(size: 20, weight: .medium))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Edit Set Name")
        }
        .padding(.vertical, 12)
    }

    private func InputWordView() -> some View {
        HStack(spacing: 0) {
            TextField("Enter a word...", text: $inputText, onCommit: {
                addWord()
            })
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .focused($isInputFocused)
                .onSubmit {
                    inputText = ""
                }
                .background(Color.white)
            Button(action: addWord) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Add Word")
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
    let words = (viewModel.currentWordSet.words ?? []).sorted { (word1, word2) in
        word1.order < word2.order
    }
    return Group {
        if words.isEmpty {
            EmptyWordListView()
        } else {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    FlowLayout(spacing: 8) {
                        ForEach(words, id: \ .id) { word in
                            HStack(spacing: 8) {
                                Text(word.text)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.22, green: 0.22, blue: 0.25)) // 다크 그레이
                                Button(action: { viewModel.deleteWord(word) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.gray)
                                        .frame(width: 20, height: 20)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Delete \(word.text)")
                                .padding(.leading, 2)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color(red: 0.95, green: 0.95, blue: 0.97)) // #F2F2F7
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
                            .id(word.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: words.count) { _ in
                    if let last = words.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    .padding(.bottom, 8)
}

    private func OptionsView() -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                OptionButton(
                    isSelected: viewModel.currentWordSet.replaceSpaces,
                    icon: "arrow.right.to.line",
                    text: "Replace spaces with _"
                ) {
                    viewModel.currentWordSet.replaceSpaces.toggle()
                }
                OptionButton(
                    isSelected: viewModel.currentWordSet.attachSharp,
                    icon: "number",
                    text: "Add #"
                ) {
                    viewModel.currentWordSet.attachSharp.toggle()
                }
                OptionButton(
                    isSelected: viewModel.currentWordSet.generateCombinations,
                    icon: "square.stack.3d.up",
                    text: "Combinations"
                ) {
                    viewModel.currentWordSet.generateCombinations.toggle()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97)) // 카드 배경 #F2F2F7
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }

    private func GenerateTagsView() -> some View {
        let canGenerate = (viewModel.currentWordSet.words?.count ?? 0) > 1
        return VStack(spacing: 20) {
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
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(!canGenerate ? Color(.systemGray3) : Color.white)
                    Text("Generate Tags")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(!canGenerate ? Color(.systemGray3) : Color.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(!canGenerate ? Color(.systemGray5) : Color.blue)
                .cornerRadius(20)
                .shadow(color: canGenerate ? Color.blue.opacity(0.12) : .clear, radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canGenerate)
            if !viewModel.generatedTags.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text("Generated Tags")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button(action: {
                            #if os(iOS)
                            UIPasteboard.general.string = viewModel.generatedTags
                            #endif
                            withAnimation {
                                showingCopiedAlert = true
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Copy")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    // 코드박스 스타일
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(viewModel.generatedTags)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
                .padding(.top, 8)
                .padding(.horizontal, 2)
                .transition(.move(edge: .bottom).combined(with: .opacity)) // 슬라이드 인 애니메이션
                .animation(.spring(), value: viewModel.generatedTags)
                HStack(spacing: 20) {
                    Button(action: {
                        UIPasteboard.general.string = viewModel.generatedTags
                        withAnimation {
                            showingCopiedAlert = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copy")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.green, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Copy")
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
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
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
                Text("Generate Tags")
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
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isInputFocused = false
            return
        }

        // Detect multi-word paste: contains '#', ',', or '\n'
        let isMultiWord = trimmed.contains("#") || trimmed.contains(",") || trimmed.contains("\n")

        if isMultiWord {
            contentViewLogger.debug("addWord: multi-word input detected, delegating to addWords")
            withAnimation {
                let result = viewModel.addWords(trimmed)
                batchImportAdded = result.added
                batchImportSkipped = result.skipped
                inputText = ""
                isInputFocused = true
            }
            showingBatchImportAlert = true
        } else {
            withAnimation {
                if !viewModel.addWord(trimmed) {
                    duplicateWord = trimmed
                    showingDuplicateAlert = true
                }
                inputText = ""
                isInputFocused = true
            }
        }
    }
}

struct OptionButton: View {
    let isSelected: Bool
    let icon: String
    let text: LocalizedStringKey
    let action: () -> Void
    var isDisabled: Bool = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDisabled ? Color(.systemGray3) : (isSelected ? Color.white : Color.gray))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDisabled ? Color(.systemGray3) : (isSelected ? Color.white : Color.gray))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isDisabled ? Color(.systemGray5) : (isSelected ? Color.blue : Color(.systemGray5)))
            .cornerRadius(16)
            .shadow(color: isSelected && !isDisabled ? Color.blue.opacity(0.12) : .clear, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isSyncing: .constant(false))
    }
}
