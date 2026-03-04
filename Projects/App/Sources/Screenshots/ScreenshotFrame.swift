#if DEBUG
import SwiftUI

// MARK: - Canvas dimensions
// Target: 1290 × 2796 pt (iPhone 6.7")
// Bottom bar: 699 pt (25 %), top content: 2097 pt (75 %)

// MARK: - Reusable frame container

struct ScreenshotFrame<Content: View>: View {
    let barColor: Color
    let headline: String
    let subheadline: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 12) {
                Text(headline)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)

                Text(subheadline)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 48)
            .frame(maxWidth: .infinity)
            .frame(height: 699)
            .background(barColor)
        }
    }
}

// MARK: - Brand palette

extension Color {
    static let ssIndigo = Color(red: 0.227, green: 0.227, blue: 0.549)
    static let ssBlue   = Color(red: 0.102, green: 0.337, blue: 0.800)
    static let ssSlate  = Color(red: 0.173, green: 0.243, blue: 0.361)
    static let ssTeal   = Color(red: 0.051, green: 0.431, blue: 0.431)
    static let ssPurple = Color(red: 0.290, green: 0.176, blue: 0.549)
}

// MARK: - Shared mock chip component

private struct MockWordChip: View {
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(red: 0.22, green: 0.22, blue: 0.25))

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(.systemGray3))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

// MARK: - Shared mock option toggle

private struct MockOptionToggle: View {
    let icon: String
    let label: String
    var isOn: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isOn ? .white : Color(.systemGray))
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isOn ? .white : Color(.systemGray))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isOn ? Color.blue : Color(.systemGray5))
        .cornerRadius(16)
    }
}

// MARK: - Frame 1: Add Your Niche Keywords

struct Screenshot1: View {
    private let chips = ["Seoul", "Gyeongbokgung", "Bukchon", "hanok", "street food", "night market", "Hongdae", "temple"]

    var body: some View {
        ScreenshotFrame(
            barColor: .ssIndigo,
            headline: "Add Your Niche\nKeywords",
            subheadline: "Build word sets for every topic you post about"
        ) {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Travel Korea")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .padding(8)
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .medium))
                        .padding(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Divider()
                    .padding(.bottom, 12)

                // Input row
                HStack(spacing: 0) {
                    Text("K-culture")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)

                    Spacer()

                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Chip flow
                FlowLikeLayout(chips: chips)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        }
    }
}

// A simple wrapping chip grid for the mock (avoids importing real FlowLayout)
private struct FlowLikeLayout: View {
    let chips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { chip in
                        MockWordChip(label: chip)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // Distribute chips into rows of 2–3 for visual balance
    private var rows: [[String]] {
        var result: [[String]] = []
        var current: [String] = []
        for (index, chip) in chips.enumerated() {
            current.append(chip)
            let maxInRow = (index % 5 < 2) ? 3 : 2
            if current.count >= maxInRow {
                result.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

// MARK: - Frame 2: One Tap. Every Combination.

struct Screenshot2: View {
    private let previewTags = [
        "#cafe", "#latte", "#Seoul", "#aesthetic",
        "#minimal", "#cafe_latte", "#cafe_Seoul", "#cafe_aesthetic"
    ]

    var body: some View {
        ScreenshotFrame(
            barColor: .ssBlue,
            headline: "One Tap.\nEvery Combination.",
            subheadline: "Generate every hashtag permutation automatically"
        ) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Cafe Aesthetic")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Color.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Divider()
                    .padding(.bottom, 12)

                // Options row
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    MockOptionToggle(icon: "arrow.right.to.line", label: "Replace spaces", isOn: true)
                    MockOptionToggle(icon: "number", label: "Add #", isOn: true)
                    MockOptionToggle(icon: "square.stack.3d.up", label: "Combos", isOn: true)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                .cornerRadius(18)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Generate button
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Generate Tags")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(20)
                .shadow(color: Color.blue.opacity(0.20), radius: 4, x: 0, y: 2)
                .padding(.bottom, 24)

                // Result card
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.blue)
                        Text("Generated Tags")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()

                        // Badge
                        Text("26 tags generated")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Tag preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text(previewTags.joined(separator: ", "))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("… and 18 more")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.secondary.opacity(0.70))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        }
    }
}

// MARK: - Frame 3: Save Sets for Every Topic

private struct MockWordSetRow: View {
    let name: String
    let wordCount: Int
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Left accent border for active row
            if isActive {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .cornerRadius(2)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isActive ? Color.blue : Color.primary)
                    Text("\(wordCount) words")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(isActive ? Color.blue.opacity(0.06) : Color.white)
        }
    }
}

struct Screenshot3: View {
    var body: some View {
        ScreenshotFrame(
            barColor: .ssSlate,
            headline: "Save Sets for\nEvery Topic",
            subheadline: "Switch between sets in seconds"
        ) {
            VStack(spacing: 0) {
                HStack {
                    Text("Word Sets")
                        .font(.system(size: 22, weight: .bold))
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.blue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

                VStack(spacing: 0) {
                    MockWordSetRow(name: "Travel Korea", wordCount: 14, isActive: true)
                    Divider().padding(.leading, 16)
                    MockWordSetRow(name: "Cafe Aesthetic", wordCount: 5)
                    Divider().padding(.leading, 16)
                    MockWordSetRow(name: "Fitness Goals", wordCount: 8)
                    Divider().padding(.leading, 16)
                    MockWordSetRow(name: "K-Drama Fandom", wordCount: 11)
                    Divider().padding(.leading, 16)
                    MockWordSetRow(name: "Street Food", wordCount: 6)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
        }
    }
}

// MARK: - Frame 4: Copy or Share Instantly

struct Screenshot4: View {
    private let tags = [
        "#travel", "#Seoul", "#Korea", "#food",
        "#travel_Seoul", "#travel_Korea", "#travel_food",
        "#Seoul_Korea", "#Seoul_food", "#Korea_food",
        "#travel_Seoul_Korea", "#travel_Seoul_food",
        "#travel_Korea_food", "#Seoul_Korea_food",
        "#travel_Seoul_Korea_food"
    ]

    var body: some View {
        ScreenshotFrame(
            barColor: .ssTeal,
            headline: "Copy or Share\nInstantly",
            subheadline: "One tap to copy all tags or share anywhere"
        ) {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color(red: 0.051, green: 0.431, blue: 0.431))
                        Text("Generated Tags")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(red: 0.051, green: 0.431, blue: 0.431))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 48) // space for toast
                    .padding(.bottom, 8)

                    // Result card
                    VStack(alignment: .leading, spacing: 0) {
                        Text(tags.joined(separator: ", "))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                    // Action buttons
                    HStack(spacing: 20) {
                        // Copy All button — filled teal
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copy All 64 Tags")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.051, green: 0.431, blue: 0.431))
                        .cornerRadius(20)

                        // Share button — outlined teal
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.051, green: 0.431, blue: 0.431))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(red: 0.051, green: 0.431, blue: 0.431), lineWidth: 1.5)
                        )
                    }

                    Spacer()
                }
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))

                // Toast overlay — top of content area
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text("16 of 64 shown")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0.051, green: 0.431, blue: 0.431))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Frame 5: Synced Across All Your Devices

struct Screenshot5: View {
    var body: some View {
        ScreenshotFrame(
            barColor: .ssPurple,
            headline: "Synced Across\nAll Your Devices",
            subheadline: "iCloud keeps your word sets updated everywhere"
        ) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Word Sets")
                            .font(.system(size: 22, weight: .bold))
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 0.290, green: 0.176, blue: 0.549))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                    VStack(spacing: 0) {
                        MockWordSetRow(name: "Travel Korea", wordCount: 14, isActive: true)
                        Divider().padding(.leading, 16)
                        MockWordSetRow(name: "Cafe Aesthetic", wordCount: 5)
                        Divider().padding(.leading, 16)
                        MockWordSetRow(name: "Fitness Goals", wordCount: 8)
                        Divider().padding(.leading, 16)
                        MockWordSetRow(name: "K-Drama Fandom", wordCount: 11)
                        Divider().padding(.leading, 16)
                        MockWordSetRow(name: "Street Food", wordCount: 6)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .background(Color(red: 0.95, green: 0.95, blue: 0.97))

                // iCloud badge — floating pill top-right
                HStack(spacing: 6) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.290, green: 0.176, blue: 0.549))
                    Text("iCloud Sync")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.290, green: 0.176, blue: 0.549))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .padding(.top, 32)
                .padding(.trailing, 20)
            }
        }
    }
}

// MARK: - Previews

#Preview("Frame 1") {
    Screenshot1()
        .frame(width: 393, height: 852)
        .previewDisplayName("Add Keywords")
}

#Preview("Frame 2") {
    Screenshot2()
        .frame(width: 393, height: 852)
        .previewDisplayName("Combinations")
}

#Preview("Frame 3") {
    Screenshot3()
        .frame(width: 393, height: 852)
        .previewDisplayName("Save Sets")
}

#Preview("Frame 4") {
    Screenshot4()
        .frame(width: 393, height: 852)
        .previewDisplayName("Copy or Share")
}

#Preview("Frame 5") {
    Screenshot5()
        .frame(width: 393, height: 852)
        .previewDisplayName("iCloud Sync")
}
#endif
