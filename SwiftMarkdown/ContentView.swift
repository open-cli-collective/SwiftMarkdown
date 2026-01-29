import SwiftUI
import SwiftMarkdownCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftMarkdown")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(SwiftMarkdownCore.version)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A modern markdown preview app for macOS")
                .font(.body)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
