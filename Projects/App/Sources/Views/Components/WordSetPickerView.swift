import SwiftUI
import SwiftData

struct WordSetPickerView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isPresented: Bool
    @State private var showingDeleteAlert = false
    @State private var wordSetToDelete: WordSetModel?
    
    var body: some View {
        NavigationView {
            wordSetList
        }
        .alert("Delete WordSet", isPresented: $showingDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text("Are you sure you want to delete this WordSet? All tags will be deleted as well.")
        }
    }
    
    private var wordSetList: some View {
        List {
            ForEach(viewModel.wordSets) { wordSet in
                wordSetRow(wordSet)
            }
        }
        .navigationTitle("WordSet Selection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    isPresented = false
                }
            }
        }
    }
    
    private func wordSetRow(_ wordSet: WordSetModel) -> some View {
        HStack {
            wordSetInfo(wordSet)
            Spacer()
            selectionIndicator(for: wordSet)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.loadWord(set: wordSet)
            isPresented = false
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            deleteSwipeAction(for: wordSet)
        }
    }
    
    private func wordSetInfo(_ wordSet: WordSetModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(wordSet.name.isEmpty ? "Default" : wordSet.name)
                .font(.system(size: 16, weight: .medium))
            Text("\(wordSet.words?.count ?? 0) words")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    private func selectionIndicator(for wordSet: WordSetModel) -> some View {
        Group {
            if wordSet.id == viewModel.currentWordSet.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
    
    private func deleteSwipeAction(for wordSet: WordSetModel) -> some View {
        Group {
            if viewModel.wordSets.count > 1 {
                Button("Delete", role: .destructive) {
                    wordSetToDelete = wordSet
                    showingDeleteAlert = true
                }
            }
        }
    }
    
    private var deleteAlertButtons: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let wordSet = wordSetToDelete {
                    deleteWordSet(wordSet)
                }
            }
        }
    }
    
    private func deleteWordSet(_ wordSet: WordSetModel) {
        if let index = viewModel.wordSets.firstIndex(where: { $0.id == wordSet.id }) {
            viewModel.wordSets.remove(at: index)
            
            // 현재 선택된 WordSet이 삭제된 경우, 첫 번째 WordSet으로 변경
            if wordSet.id == viewModel.currentWordSet.id {
                viewModel.currentWordSet = viewModel.wordSets.first
            }
            
            // WordSetManager에서 삭제
            WordSetManager.shared.deleteWordSet(wordSet)
        }
    }
}

struct WordSetPickerView_Previews: PreviewProvider {
    static var previews: some View {
        WordSetPickerView(viewModel: MainViewModel(), isPresented: .constant(true))
    }
}
