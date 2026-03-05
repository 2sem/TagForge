import SwiftUI

struct GeneratedTagsSheet: View {
    @ObservedObject var viewModel: MainViewModel;
    @State private var removedIds: Swift.Set<UUID> = [];
    @State private var showCopied: Bool = false;

    private var visibleTags: [GeneratedTag] {
        viewModel.generatedTagList.filter { !removedIds.contains($0.id) };
    }

    private var copyableString: String {
        let separator = viewModel.currentWordSet.attachSharp ? " " : ", ";
        return visibleTags.map(\.text).joined(separator: separator);
    }

    private var charCount: Int { copyableString.count; }
    private var removedCount: Int { removedIds.count; }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(NSLocalizedString("sheet.generatedTags.title", comment: ""))
                    .font(.headline)
                Spacer()
                Text(String(format: NSLocalizedString("sheet.generatedTags.counter", comment: ""), visibleTags.count, charCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Tag chips or empty state
            if visibleTags.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("sheet.generatedTags.empty", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(visibleTags) { tag in
                            tagChip(tag)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            // Toolbar
            Divider()
            HStack(spacing: 12) {
                if removedCount > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            removedIds.removeAll();
                        }

                    } label: {
                        Text(String(format: NSLocalizedString("sheet.generatedTags.reset", comment: ""), removedCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = copyableString
                    showCopied = true
                } label: {
                    Label(NSLocalizedString("sheet.generatedTags.copy", comment: ""), systemImage: "doc.on.doc")
                }
                .onChange(of: showCopied) { _, newValue in
                    guard newValue else { return }
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        showCopied = false
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(visibleTags.isEmpty)

                ShareLink(item: copyableString) {
                    Label(NSLocalizedString("sheet.generatedTags.share", comment: ""), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(visibleTags.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, 4)
            .background(.regularMaterial)
        }
        .overlay(alignment: .bottom) {
            if showCopied {
                Text(NSLocalizedString("sheet.generatedTags.copied", comment: ""))
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 80)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopied)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onDisappear {
            removedIds.removeAll();
        }
    }

    private func tagChip(_ tag: GeneratedTag) -> some View {
        HStack(spacing: 6) {
            Text(tag.text)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(2)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    _ = removedIds.insert(tag.id);
                }

            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Color(.systemGray4))
                    .clipShape(Circle())
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(String(format: NSLocalizedString("sheet.generatedTags.removeTag", comment: ""), tag.text))
        }
        .padding(.vertical, 7)
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}
