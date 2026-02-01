import Foundation
import SwiftTreeSitter

/// A syntax highlighter that lazily loads grammars on demand.
///
/// This highlighter uses `GrammarManager` to download and cache tree-sitter
/// grammars from GitHub releases. Grammars installed via Homebrew or already
/// cached are available synchronously, while missing grammars are downloaded
/// asynchronously on first use.
///
/// ## Synchronous vs Asynchronous API
///
/// - **Synchronous API** (`highlight`, `highlightToHTML`) - Works with any installed
///   grammar (Homebrew or cache). Returns empty tokens/escaped HTML for non-installed languages.
/// - **Async API** (`highlightAsync`, `highlightToHTMLAsync`) - Downloads missing grammars
///   automatically. Use this when you want full language support.
///
/// ## Example
/// ```swift
/// let highlighter = LazyTreeSitterHighlighter()
///
/// // Async API for lazy-loaded grammars
/// let html = await highlighter.highlightToHTMLAsync(code: jsCode, language: "javascript")
///
/// // Sync API falls back to plain text for non-installed languages
/// let html = highlighter.highlightToHTML(code: code, language: "python")  // Returns escaped code if not installed
/// ```
public final class LazyTreeSitterHighlighter: HTMLSyntaxHighlighter, @unchecked Sendable {
    /// Shared highlighter instance for caching grammar configurations across renders.
    public static let shared = LazyTreeSitterHighlighter()

    private let parser: Parser
    private let grammarManager: GrammarManager
    private var languageConfigs: [String: LanguageConfiguration] = [:]
    private let configLock = NSLock()

    /// Cache of parsed tokens keyed by language + code hash.
    /// Avoids re-parsing identical code blocks on file reload or theme changes.
    private var tokenCache: [String: [HighlightToken]] = [:]
    private let cacheLock = NSLock()

    /// Creates a new lazy highlighter.
    ///
    /// - Parameter grammarManager: The grammar manager to use. Defaults to shared instance.
    public init(grammarManager: GrammarManager = .shared) {
        self.parser = Parser()
        self.grammarManager = grammarManager
    }

    // MARK: - SyntaxHighlighter Protocol

    public var supportedLanguages: [String] {
        // Synchronously return only installed languages
        grammarManager.installedGrammars()
    }

    public func supportsLanguage(_ language: String) -> Bool {
        // Synchronously check only installed languages
        grammarManager.isGrammarInstalled(language.lowercased())
    }

    public func highlight(code: String, language: String) -> [HighlightToken] {
        let langLower = language.lowercased()

        guard grammarManager.isGrammarInstalled(langLower) else {
            return []
        }

        let cacheKey = makeCacheKey(language: langLower, code: code)

        cacheLock.lock()
        if let cached = tokenCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        configLock.lock()
        defer { configLock.unlock() }

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

        let tokens = TreeSitterTokenProcessor.extractTokens(from: tree, code: code, query: query)

        cacheLock.lock()
        tokenCache[cacheKey] = tokens
        cacheLock.unlock()

        return tokens
    }

    public func highlightToHTML(code: String, language: String) -> String {
        // Only works for installed grammars
        guard grammarManager.isGrammarInstalled(language.lowercased()) else {
            return code.htmlEscaped
        }

        let tokens = highlight(code: code, language: language)
        guard !tokens.isEmpty else {
            return code.htmlEscaped
        }

        return TreeSitterTokenProcessor.renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Async API

    /// Asynchronously checks if a language is supported (includes lazy-loaded grammars).
    public func supportsLanguageAsync(_ language: String) async -> Bool {
        await grammarManager.supportsLanguage(language)
    }

    /// Returns all supported languages including lazy-loaded ones.
    public func supportedLanguagesAsync() async -> [String] {
        await grammarManager.supportedLanguages()
    }

    /// Asynchronously highlights code, downloading the grammar if needed.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The language identifier.
    /// - Returns: An array of highlight tokens, or empty if unsupported.
    public func highlightAsync(code: String, language: String) async -> [HighlightToken] {
        // Try to load grammar (may download if not installed)
        guard let grammar = try? await grammarManager.grammar(for: language) else {
            return []
        }

        return await highlightWithGrammar(code: code, grammar: grammar)
    }

    /// Asynchronously highlights code to HTML, downloading the grammar if needed.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The language identifier.
    /// - Returns: HTML string with token spans, or escaped code if unsupported.
    public func highlightToHTMLAsync(code: String, language: String) async -> String {
        let tokens = await highlightAsync(code: code, language: language)
        guard !tokens.isEmpty else {
            return code.htmlEscaped
        }
        return TreeSitterTokenProcessor.renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Cache Management

    /// Clears the token cache. Call when grammars are updated or to free memory.
    public func clearTokenCache() {
        cacheLock.lock()
        tokenCache.removeAll()
        cacheLock.unlock()
    }

    /// Returns the number of cached token sets (for diagnostics).
    public var tokenCacheCount: Int {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return tokenCache.count
    }

    // MARK: - Private Implementation

    private func makeCacheKey(language: String, code: String) -> String {
        "\(language):\(code.hashValue)"
    }

    /// Synchronously loads a grammar configuration if the grammar is installed locally.
    private func getOrLoadConfig(for language: String) -> LanguageConfiguration? {
        if let cached = languageConfigs[language] {
            return cached
        }

        guard let grammar = GrammarLoader.loadGrammarSync(language, cacheURL: grammarManager.cacheDirectory) else {
            return nil
        }

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

    private func highlightWithGrammar(code: String, grammar: LoadedGrammar) async -> [HighlightToken] {
        let cacheKey = makeCacheKey(language: grammar.name, code: code)

        cacheLock.lock()
        if let cached = tokenCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        configLock.lock()
        defer { configLock.unlock() }

        let config: LanguageConfiguration
        if let cached = languageConfigs[grammar.name] {
            config = cached
        } else {
            guard FileManager.default.fileExists(atPath: grammar.queriesURL.path),
                  let querySource = try? String(contentsOf: grammar.queriesURL) else {
                return []
            }

            do {
                guard let queryData = querySource.data(using: .utf8) else {
                    return []
                }
                let query = try Query(language: grammar.language, data: queryData)
                let queries: [Query.Definition: Query] = [.highlights: query]
                config = LanguageConfiguration(grammar.language, name: grammar.name, queries: queries)
                languageConfigs[grammar.name] = config
            } catch {
                return []
            }
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

        let tokens = TreeSitterTokenProcessor.extractTokens(from: tree, code: code, query: query)

        cacheLock.lock()
        tokenCache[cacheKey] = tokens
        cacheLock.unlock()

        return tokens
    }
}
