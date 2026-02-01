import Foundation
import SwiftTreeSitter

/// A syntax highlighter that uses tree-sitter for accurate parsing.
///
/// Supports any language that has a grammar installed via Homebrew or cached
/// in Application Support. Uses GrammarManager to discover and load grammars.
///
/// ## Example
/// ```swift
/// let highlighter = TreeSitterHighlighter()
/// let html = highlighter.highlightToHTML(code: "let x = 1", language: "swift")
/// // "<span class="token-keyword">let</span> x <span class="token-operator">=</span> <span class="token-number">1</span>"
/// ```
///
/// ## Thread Safety
///
/// This class is thread-safe via NSLock protection around parser operations.
public final class TreeSitterHighlighter: HTMLSyntaxHighlighter, @unchecked Sendable {
    private let parser: Parser
    private let grammarManager: GrammarManager
    private var languageConfigs: [String: LanguageConfiguration] = [:]
    private let configLock = NSLock()

    /// Creates a new highlighter.
    ///
    /// - Parameter grammarManager: The grammar manager to use. Defaults to shared instance.
    public init(grammarManager: GrammarManager = .shared) {
        self.parser = Parser()
        self.grammarManager = grammarManager
    }

    public var supportedLanguages: [String] {
        // Return only installed grammars (Homebrew + cache)
        grammarManager.installedGrammars()
    }

    public func supportsLanguage(_ language: String) -> Bool {
        grammarManager.isGrammarInstalled(language.lowercased())
    }

    public func highlight(code: String, language: String) -> [HighlightToken] {
        let langLower = language.lowercased()
        guard grammarManager.isGrammarInstalled(langLower) else {
            return []
        }

        configLock.lock()
        defer { configLock.unlock() }

        // Get or create configuration
        guard let config = getOrLoadConfig(for: langLower) else {
            return []
        }

        do {
            try parser.setLanguage(config.language)
        } catch {
            return []
        }

        guard let tree = parser.parse(code),
              let query = config.queries[.highlights] else {
            return []
        }

        return TreeSitterTokenProcessor.extractTokens(from: tree, code: code, query: query)
    }

    public func highlightToHTML(code: String, language: String) -> String {
        guard grammarManager.isGrammarInstalled(language.lowercased()) else {
            return code.htmlEscaped
        }

        let tokens = highlight(code: code, language: language)
        guard !tokens.isEmpty else {
            return code.htmlEscaped
        }

        return TreeSitterTokenProcessor.renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Private Implementation

    /// Synchronously loads a grammar configuration if the grammar is installed.
    private func getOrLoadConfig(for language: String) -> LanguageConfiguration? {
        // Return cached config if available
        if let cached = languageConfigs[language] {
            return cached
        }

        // Try to load from disk (Homebrew or cache)
        guard let grammar = GrammarLoader.loadGrammarSync(language, cacheURL: grammarManager.cacheDirectory) else {
            return nil
        }

        // Load highlights.scm
        guard FileManager.default.fileExists(atPath: grammar.queriesURL.path),
              let querySource = try? String(contentsOf: grammar.queriesURL) else {
            return nil
        }

        do {
            guard let queryData = querySource.data(using: .utf8) else {
                return nil
            }
            let query = try Query(language: grammar.language, data: queryData)
            let queries: [Query.Definition: Query] = [.highlights: query]
            let config = LanguageConfiguration(grammar.language, name: grammar.name, queries: queries)
            languageConfigs[language] = config
            return config
        } catch {
            return nil
        }
    }
}
