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

        return extractTokens(from: tree, code: code, query: query)
    }

    public func highlightToHTML(code: String, language: String) -> String {
        guard supportsLanguage(language) else {
            return escapeHTML(code)
        }

        let tokens = highlight(code: code, language: language)
        guard !tokens.isEmpty else {
            return escapeHTML(code)
        }

        return renderTokensToHTML(code: code, tokens: tokens)
    }

    // MARK: - Private

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

                // Convert byte range to string indices
                guard let range = byteRangeToStringRange(byteRange, in: code) else {
                    continue
                }

                tokens.append(HighlightToken(range: range, tokenType: tokenType))
            }
        }

        // Sort by range start and remove overlaps (prefer longer matches)
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

        // Convert UTF-8 indices to String.Index
        guard let start = String.Index(startIndex, within: string),
              let end = String.Index(endIndex, within: string) else {
            return nil
        }

        return start..<end
    }

    /// Mapping of tree-sitter capture name prefixes to token types.
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
        // Sort by start position
        let sorted = tokens.sorted { $0.range.lowerBound < $1.range.lowerBound }

        // Remove overlapping tokens (keep the first one in sorted order)
        var result: [HighlightToken] = []
        var lastEnd: String.Index?

        for token in sorted {
            if let end = lastEnd, token.range.lowerBound < end {
                // This token overlaps with the previous one, skip it
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
            // Add any unhighlighted text before this token
            if currentIndex < token.range.lowerBound {
                result += escapeHTML(String(code[currentIndex..<token.range.lowerBound]))
            }

            // Add the highlighted token
            let tokenText = String(code[token.range])
            if token.tokenType != .plain {
                result += "<span class=\"token-\(token.tokenType.rawValue)\">"
                result += escapeHTML(tokenText)
                result += "</span>"
            } else {
                result += escapeHTML(tokenText)
            }

            currentIndex = token.range.upperBound
        }

        // Add any remaining text after the last token
        if currentIndex < code.endIndex {
            result += escapeHTML(String(code[currentIndex...]))
        }

        return result
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
