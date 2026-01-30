import Foundation
import SwiftTreeSitter
import TreeSitterSwift

/// A syntax highlighter that uses tree-sitter for accurate parsing.
///
/// Currently supports Swift highlighting, with architecture designed for
/// additional languages to be added.
///
/// ## Example
/// ```swift
/// let highlighter = TreeSitterHighlighter()
/// let html = highlighter.highlightToHTML(code: "let x = 1", language: "swift")
/// // "<span class="token-keyword">let</span> x <span class="token-operator">=</span> <span class="token-number">1</span>"
/// ```
public final class TreeSitterHighlighter: HTMLSyntaxHighlighter, @unchecked Sendable {
    private let parser: Parser
    private var swiftConfig: LanguageConfiguration?

    public init() {
        self.parser = Parser()

        do {
            // LanguageConfiguration handles loading the language and bundled queries
            swiftConfig = try LanguageConfiguration(
                tree_sitter_swift(),
                name: "Swift"
            )
            if let config = swiftConfig {
                try parser.setLanguage(config.language)
            }
        } catch {
            // If configuration fails, highlighting will fall back to plain text
            swiftConfig = nil
        }
    }

    public var supportedLanguages: [String] {
        ["swift"]
    }

    public func supportsLanguage(_ language: String) -> Bool {
        supportedLanguages.contains(language.lowercased())
    }

    public func highlight(code: String, language: String) -> [HighlightToken] {
        guard supportsLanguage(language),
              let config = swiftConfig,
              let query = config.queries[.highlights],
              let tree = parser.parse(code) else {
            return []
        }

        return TreeSitterTokenProcessor.extractTokens(from: tree, code: code, query: query)
    }

    public func highlightToHTML(code: String, language: String) -> String {
        guard supportsLanguage(language) else {
            return code.htmlEscaped
        }

        let tokens = highlight(code: code, language: language)
        guard !tokens.isEmpty else {
            return code.htmlEscaped
        }

        return TreeSitterTokenProcessor.renderTokensToHTML(code: code, tokens: tokens)
    }
}
