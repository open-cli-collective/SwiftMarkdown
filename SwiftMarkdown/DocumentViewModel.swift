import Foundation
import SwiftMarkdownCore
import UniformTypeIdentifiers

/// View model for managing a markdown document.
@MainActor
final class DocumentViewModel: ObservableObject {
    @Published var fileURL: URL?
    @Published var renderedHTML: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// The file name to display in the title bar.
    var fileName: String {
        fileURL?.lastPathComponent ?? "SwiftMarkdown"
    }

    /// Check if a URL points to a valid markdown file.
    nonisolated static func isMarkdownFile(_ url: URL) -> Bool {
        MarkdownFileValidator.isMarkdownFile(url)
    }

    /// Load and render a markdown file.
    func loadFile(at url: URL) async {
        // Validate file extension and content
        let validationResult = MarkdownFileValidator.validate(url)
        guard validationResult.isValid else {
            errorMessage = validationResult.errorMessage ?? "Invalid file"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let html = await renderMarkdown(content)

            fileURL = url
            renderedHTML = html
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Render markdown content to HTML with syntax highlighting.
    private func renderMarkdown(_ content: String) async -> String {
        let document = MarkdownParser.parseDocument(content)
        let highlighter = LazyTreeSitterHighlighter()
        let renderer = HTMLRenderer(wrapInDocument: true)
        return await renderer.renderAsync(document, highlighter: highlighter)
    }

    /// Clear the current document.
    func clearDocument() {
        fileURL = nil
        renderedHTML = ""
        errorMessage = nil
    }
}
