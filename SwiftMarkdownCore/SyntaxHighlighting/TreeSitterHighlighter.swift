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
        guard let grammar = loadGrammarSync(language) else {
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
            _ = try Query(language: grammar.language, data: queryData)
            let config = try LanguageConfiguration(grammar.language, name: grammar.name)
            languageConfigs[language] = config
            return config
        } catch {
            return nil
        }
    }

    /// Synchronously loads a grammar from Homebrew or cache.
    /// Returns nil if grammar is not installed locally.
    private func loadGrammarSync(_ name: String) -> LoadedGrammar? {
        // Check Homebrew directories
        let homebrewPrefixes = ["/opt/homebrew", "/usr/local"]
        for prefix in homebrewPrefixes {
            let homebrewURL = URL(fileURLWithPath: "\(prefix)/share/swiftmarkdown-grammars")
            let grammarDir = homebrewURL.appendingPathComponent(name)
            let dylibURL = grammarDir.appendingPathComponent("\(name).dylib")
            let queriesURL = grammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

            if FileManager.default.fileExists(atPath: dylibURL.path) {
                if let grammar = loadFromDisk(name: name, dylibURL: dylibURL, queriesURL: queriesURL) {
                    return grammar
                }
            }
        }

        // Check cache directory
        // swiftlint:disable:next force_unwrapping
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheURL = appSupport.appendingPathComponent("SwiftMarkdown").appendingPathComponent("Grammars")
        let cacheGrammarDir = cacheURL.appendingPathComponent(name)
        let cacheDylibURL = cacheGrammarDir.appendingPathComponent("\(name).dylib")
        let cacheQueriesURL = cacheGrammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

        if FileManager.default.fileExists(atPath: cacheDylibURL.path) {
            return loadFromDisk(name: name, dylibURL: cacheDylibURL, queriesURL: cacheQueriesURL)
        }

        return nil
    }

    private func loadFromDisk(name: String, dylibURL: URL, queriesURL: URL) -> LoadedGrammar? {
        guard let handle = dlopen(dylibURL.path, RTLD_NOW) else {
            return nil
        }

        let symbolName = "tree_sitter_\(name)"
        guard let symbol = dlsym(handle, symbolName) else {
            return nil
        }

        typealias LanguageFunc = @convention(c) () -> OpaquePointer
        let languageFunc = unsafeBitCast(symbol, to: LanguageFunc.self)
        let languagePtr = languageFunc()

        let language = Language(language: languagePtr)

        return LoadedGrammar(
            language: language,
            queriesURL: queriesURL,
            name: name
        )
    }
}
