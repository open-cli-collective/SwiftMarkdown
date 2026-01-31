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

    /// Current render task, used for cancellation when a new file is loaded.
    private var renderTask: Task<Void, Never>?

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
        // Cancel any in-flight render before starting a new one
        renderTask?.cancel()

        // Validate file extension and content
        let validationResult = MarkdownFileValidator.validate(url)
        guard validationResult.isValid else {
            errorMessage = validationResult.errorMessage ?? "Invalid file"
            return
        }

        isLoading = true
        errorMessage = nil

        renderTask = Task {
            do {
                try Task.checkCancellation()

                // Read file on background thread to avoid blocking UI
                let content = try await Task.detached {
                    try String(contentsOf: url, encoding: .utf8)
                }.value

                try Task.checkCancellation()
                let html = await renderMarkdown(content)

                try Task.checkCancellation()
                fileURL = url
                renderedHTML = html
            } catch is CancellationError {
                // Silently ignore - a new file load superseded this one
            } catch {
                errorMessage = "Failed to load file: \(error.localizedDescription)"
            }

            isLoading = false
        }

        await renderTask?.value
    }

    /// Render markdown content to HTML with syntax highlighting.
    private func renderMarkdown(_ content: String) async -> String {
        let document = MarkdownParser.parseDocument(content)
        let renderer = HTMLRenderer(wrapInDocument: true)
        return await renderer.renderAsync(document, highlighter: LazyTreeSitterHighlighter.shared)
    }

    /// Clear the current document.
    func clearDocument() {
        fileURL = nil
        renderedHTML = ""
        errorMessage = nil
    }
}
