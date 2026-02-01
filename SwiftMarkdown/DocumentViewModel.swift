import AppKit
import Foundation
import Markdown
import SwiftMarkdownCore
import UniformTypeIdentifiers

/// View model for managing a markdown document.
@MainActor
final class DocumentViewModel: ObservableObject {
    @Published var fileURL: URL?
    @Published var renderedContent: NSAttributedString = NSAttributedString()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Current render task, used for cancellation when a new file is loaded.
    private var renderTask: Task<Void, Never>?

    /// Background task for loading missing grammars.
    private var grammarLoadTask: Task<Void, Never>?

    /// Cached renderer to avoid repeated allocation on every render.
    private let renderer = DocumentRenderer(syntaxHighlighter: LazyTreeSitterHighlighter.shared)

    /// Reference to shared highlighter for grammar checks.
    private let highlighter = LazyTreeSitterHighlighter.shared

    /// The file name to display in the title bar.
    var fileName: String {
        fileURL?.lastPathComponent ?? "SwiftMarkdown"
    }

    /// Check if a URL points to a valid markdown file.
    nonisolated static func isMarkdownFile(_ url: URL) -> Bool {
        MarkdownFileValidator.isMarkdownFile(url)
    }

    /// Load and render a markdown file.
    ///
    /// Uses progressive enhancement: renders immediately with installed grammars,
    /// then downloads missing grammars in background and re-renders when available.
    func loadFile(at url: URL) async {
        renderTask?.cancel()
        grammarLoadTask?.cancel()

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

                let content = try await Task.detached {
                    try String(contentsOf: url, encoding: .utf8)
                }.value

                try Task.checkCancellation()

                let document = MarkdownParser.parseDocument(content)
                let attributed = renderDocument(document)

                try Task.checkCancellation()
                fileURL = url
                renderedContent = attributed
                isLoading = false

                loadMissingGrammarsAndRerender(document: document, content: content)
            } catch is CancellationError {
                // Silently ignore - a new file load superseded this one
            } catch {
                errorMessage = "Failed to load file: \(error.localizedDescription)"
                isLoading = false
            }
        }

        await renderTask?.value
    }

    /// Render a parsed document to an attributed string.
    private func renderDocument(_ document: Document) -> NSAttributedString {
        let theme = MarkdownTheme.default
        let context = RenderContext()
        return renderer.render(document, theme: theme, context: context)
    }

    /// Load missing grammars in background and re-render when available.
    private func loadMissingGrammarsAndRerender(document: Document, content: String) {
        let languages = MarkdownParser.extractCodeBlockLanguages(from: document)
        let missingLanguages = languages.filter { !highlighter.supportsLanguage($0) }

        guard !missingLanguages.isEmpty else { return }

        grammarLoadTask = Task.detached { [weak self] in
            var anyLoaded = false

            for language in missingLanguages {
                do {
                    try Task.checkCancellation()
                    _ = try await GrammarManager.shared.grammar(for: language)
                    anyLoaded = true
                } catch {
                    // Grammar not available - continue with others
                }
            }

            if anyLoaded {
                try? Task.checkCancellation()
                await self?.rerender(content: content)
            }
        }
    }

    /// Re-render the current content (called after new grammars are available).
    private func rerender(content: String) {
        let document = MarkdownParser.parseDocument(content)
        renderedContent = renderDocument(document)
    }

    /// Clear the current document.
    func clearDocument() {
        fileURL = nil
        renderedContent = NSAttributedString()
        errorMessage = nil
    }
}
