import SwiftUI

struct ContentView: View {
    @State private var inputText: String = "" // Input word state variable
    @State private var wordList: [String] = [] // List of registered words
    @State private var generatedTags: String = "" // Generated tags as a single string
    @State private var replaceSpacesWithUnderscore: Bool = false // Option to replace spaces with underscores
    @State private var attachSharpTag: Bool = false // Option to attach sharp tag

    var body: some View {
        VStack {
            TextField("Enter a word...", text: $inputText) // Input field for words
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Add Word") {
                addWord() // Button to add a word
            }
            .padding()

            List {
                ForEach(wordList, id: \.self) { word in
                    Text(word) // Display registered words
                }
                .onDelete(perform: deleteWords) // Swipe to delete functionality
            }
            .padding()

            Toggle("Replace spaces with _", isOn: $replaceSpacesWithUnderscore) // Checkbox to replace spaces
                .padding()

            Toggle("Sharp Tag", isOn: $attachSharpTag) // Checkbox to attach sharp tag
                .padding()

            Button("Generate Tags") {
                generateTags() // Button to generate tags
            }
            .padding()

            // Display generated tags
            Text(generatedTags) // Display generated tags
                .padding(5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .padding()
        }
        .padding()
    }

    private func addWord() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            wordList.append(trimmedText) // Add the entered word to the list
            inputText = "" // Clear the input field
        }
    }

    private func deleteWords(at offsets: IndexSet) {
        wordList.remove(atOffsets: offsets) // Remove words with swipe
    }

    private func generateTags() {
        var tags = wordList.map { word in
            var tag = word
            if replaceSpacesWithUnderscore {
                tag = tag.replacingOccurrences(of: " ", with: "_") // Replace spaces with underscores
            }
            if attachSharpTag {
                tag = "#" + tag // Attach sharp tag
            }
            return tag
        }
        generatedTags = tags.joined(separator: ", ") // Join tags into a single string
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 