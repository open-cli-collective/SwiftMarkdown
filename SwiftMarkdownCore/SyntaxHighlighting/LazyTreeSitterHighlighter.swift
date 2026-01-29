import Foundation
import SwiftTreeSitter
import TreeSitterSwift

/// A syntax highlighter that lazily loads grammars on demand.
///
/// This highlighter uses `GrammarManager` to download and cache tree-sitter
/// grammars from GitHub releases. Swift is always available (bundled),
/// while other languages are downloaded on first use.
///
/// ## Example
/// ```swift
/// let highlighter = LazyTreeSitterHighlighter()
///
/// // Async API for lazy-loaded grammars
/// let html = await highlighter.highlightToHTMLAsync(code: jsCode, language: "javascript")
///
/// // Sync API falls back to plain text for non-Swift languages
/// let html = highlighter.highlightToHTML(code: code, language: "python")  // Returns escaped code
/// ```
public final class LazyTreeSitterHighlighter: HTMLSyntaxHighlighter, @unchecked Sendable {
    private let parser: Parser
    private var swiftConfig: LanguageConfiguration?
    private let grammarManager: GrammarManager
    private var languageConfigs: [String: LanguageConfiguration] = [:]
    private let configLock = NSLock()

    /// Creates a new lazy highlighter.
    ///
    /// - Parameter grammarManager: The grammar manager to use. Defaults to shared instance.
    public init(grammarManager: GrammarManager = .shared) {
        self.parser = Parser()
        self.grammarManager = grammarManager

        // Initialize bundled Swift
        do {
            swiftConfig = try LanguageConfiguration(
                tree_sitter_swift(),
                name: "Swift"
            )
        } catch {
            swiftConfig = nil
        }
    }

    // MARK: - SyntaxHighlighter Protocol

    public var supportedLanguages: [String] {
        // Synchronously return only bundled languages
        ["swift"]
    }

    public func supportsLanguage(_ language: String) -> Bool {
        // Synchronously check only bundled languages
        language.lowercased() == "swift"
    }

    public func highlight(code: String, language: String) -> [HighlightToken] {
        // Synchronous method only works for Swift
        guard language.lowercased() == "swift",
              let config = swiftConfig,
              let query = config.queries[.highlights] else {
            return []
        }

        configLock.lock()
        do {
            try parser.setLanguage(config.language)
        } catch {
            configLock.unlock()
            return []
        }

        guard let tree = parser.parse(code) else {
            configLock.unlock()
            return []
        }

        let tokens = extractTokens(from: tree, code: code, query: query)
        configLock.unlock()
        return tokens
    }

    public func highlightToHTML(code: String, language: String) -> String {
        // Synchronous method only works for Swift
        guard language.lowercased() == "swift" else {
            return code.htmlEscaped
        }

        let tokens = highlight(code: code, language: language)
        guard !tokens.isEmpty else {
            return code.htmlEscaped
        }

        return renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Async API

    /// Asynchronously checks if a language is supported (includes lazy-loaded grammars).
    public func supportsLanguageAsync(_ language: String) async -> Bool {
        if language.lowercased() == "swift" {
            return true
        }
        return await grammarManager.supportsLanguage(language)
    }

    /// Returns all supported languages including lazy-loaded ones.
    public func supportedLanguagesAsync() async -> [String] {
        var languages = await grammarManager.supportedLanguages()
        if !languages.contains("swift") {
            languages.append("swift")
        }
        return languages.sorted()
    }

    /// Asynchronously highlights code, downloading the grammar if needed.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The language identifier.
    /// - Returns: An array of highlight tokens, or empty if unsupported.
    public func highlightAsync(code: String, language: String) async -> [HighlightToken] {
        // Swift is always available synchronously
        if language.lowercased() == "swift" {
            return highlight(code: code, language: language)
        }

        // Try to load grammar
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
        return renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Private Implementation

    private func highlightWithGrammar(code: String, grammar: LoadedGrammar) async -> [HighlightToken] {
        configLock.lock()
        defer { configLock.unlock() }

        // Get or create configuration
        let config: LanguageConfiguration
        if let cached = languageConfigs[grammar.name] {
            config = cached
        } else {
            // Load highlights.scm
            guard FileManager.default.fileExists(atPath: grammar.queriesURL.path),
                  let querySource = try? String(contentsOf: grammar.queriesURL) else {
                return []
            }

            do {
                guard let queryData = querySource.data(using: .utf8) else {
                    return []
                }
                _ = try Query(language: grammar.language, data: queryData)
                config = try LanguageConfiguration(grammar.language, name: grammar.name)
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

        return extractTokens(from: tree, code: code, query: query)
    }

    private func extractTokens(from tree: MutableTree, code: String, query: Query) -> [HighlightToken] {
        let cursor = query.execute(in: tree)
        var tokens: [HighlightToken] = []

        for match in cursor {
            for capture in match.captures {
                guard let captureName = query.captureName(for: capture.index) else {
                    continue
                }

                let tokenType = mapCaptureToTokenType(captureName)
                let node = capture.node
                let byteRange = node.byteRange

                guard let range = byteRangeToStringRange(byteRange, in: code) else {
                    continue
                }

                tokens.append(HighlightToken(range: range, tokenType: tokenType))
            }
        }

        return deduplicateAndSort(tokens)
    }

    private func byteRangeToStringRange(_ byteRange: Range<UInt32>, in string: String) -> Range<String.Index>? {
        let utf8 = string.utf8
        let startOffset = Int(byteRange.lowerBound)
        let endOffset = Int(byteRange.upperBound)

        guard startOffset <= utf8.count, endOffset <= utf8.count else {
            return nil
        }

        let startIndex = utf8.index(utf8.startIndex, offsetBy: startOffset)
        let endIndex = utf8.index(utf8.startIndex, offsetBy: endOffset)

        guard let start = String.Index(startIndex, within: string),
              let end = String.Index(endIndex, within: string) else {
            return nil
        }

        return start..<end
    }

    private static let captureMapping: [(prefixes: [String], tokenType: HighlightToken.TokenType)] = [
        (["keyword"], .keyword),
        (["string"], .string),
        (["comment"], .comment),
        (["number", "constant.numeric"], .number),
        (["function", "method"], .function),
        (["type"], .type),
        (["variable", "identifier"], .variable),
        (["operator"], .operator),
        (["punctuation"], .punctuation),
        (["property", "field"], .property),
        (["attribute"], .attribute)
    ]

    private func mapCaptureToTokenType(_ name: String) -> HighlightToken.TokenType {
        let lowercased = name.lowercased()

        guard let match = Self.captureMapping.first(where: { mapping in
            mapping.prefixes.contains { lowercased.hasPrefix($0) }
        }) else {
            return .plain
        }

        return match.tokenType
    }

    private func deduplicateAndSort(_ tokens: [HighlightToken]) -> [HighlightToken] {
        let sorted = tokens.sorted { $0.range.lowerBound < $1.range.lowerBound }
        var result: [HighlightToken] = []
        var lastEnd: String.Index?

        for token in sorted {
            if let end = lastEnd, token.range.lowerBound < end {
                continue
            }
            result.append(token)
            lastEnd = token.range.upperBound
        }

        return result
    }

    private func renderTokensToHTML(code: String, tokens: [HighlightToken]) -> String {
        var result = ""
        var currentIndex = code.startIndex

        for token in tokens {
            if currentIndex < token.range.lowerBound {
                result += String(code[currentIndex..<token.range.lowerBound]).htmlEscaped
            }

            let tokenText = String(code[token.range])
            if token.tokenType != .plain {
                result += "<span class=\"token-\(token.tokenType.rawValue)\">"
                result += tokenText.htmlEscaped
                result += "</span>"
            } else {
                result += tokenText.htmlEscaped
            }

            currentIndex = token.range.upperBound
        }

        if currentIndex < code.endIndex {
            result += String(code[currentIndex...]).htmlEscaped
        }

        return result
    }
}
