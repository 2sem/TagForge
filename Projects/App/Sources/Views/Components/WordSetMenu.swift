import SwiftUI

struct WordSetMenu<Label>: View where Label : View {
    var availableSets: [WordSet]
    var onSelectWordSet: (WordSet) -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Menu(content: {
            ForEach(availableSets, id: \.name) { set in
                Button(set.name) {
                    onSelectWordSet(set)
                }
            }
        }, label: label)
    }
}

// Sample Set struct for demonstration purposes
struct Set {
    var name: String
}
