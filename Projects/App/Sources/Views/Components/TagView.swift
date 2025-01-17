import SwiftUI

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(16)
    }
} 