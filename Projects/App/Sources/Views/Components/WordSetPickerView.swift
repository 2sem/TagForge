import SwiftUI
import SwiftData

struct WordSetPickerView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var isPresented: Bool
    @State private var showingDeleteAlert = false
    @State private var wordSetToDelete: WordSetModel?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.wordSets, id: \.id) { wordSet in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wordSet.name.isEmpty ? "Default" : wordSet.name)
                                .font(.system(size: 16, weight: .medium))
                            Text("\(wordSet.words?.count ?? 0)개 태그")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if wordSet.id == viewModel.currentWordSet.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.loadWord(set: wordSet)
                        isPresented = false
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if viewModel.wordSets.count > 1 {
                            Button("삭제", role: .destructive) {
                                wordSetToDelete = wordSet
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("WordSet 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("WordSet 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                if let wordSet = wordSetToDelete {
                    deleteWordSet(wordSet)
                }
            }
        } message: {
            Text("이 WordSet을 삭제하시겠습니까? 모든 태그가 함께 삭제됩니다.")
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