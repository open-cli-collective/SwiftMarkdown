import Foundation
import SwiftTreeSitter

/// Shared utilities for processing tree-sitter tokens into highlighted HTML.
///
/// Used by both `TreeSitterHighlighter` (synchronous) and `LazyTreeSitterHighlighter` (async)
/// to avoid code duplication.
enum TreeSitterTokenProcessor {
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

    /// Extracts highlight tokens from a parsed tree using a highlight query.
    static func extractTokens(from tree: MutableTree, code: String, query: Query) -> [HighlightToken] {
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

    /// Converts a byte range from tree-sitter to a Swift String.Index range.
    static func byteRangeToStringRange(_ byteRange: Range<UInt32>, in string: String) -> Range<String.Index>? {
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

    /// Maps a tree-sitter capture name to a token type.
    static func mapCaptureToTokenType(_ name: String) -> HighlightToken.TokenType {
        let lowercased = name.lowercased()

        guard let match = captureMapping.first(where: { mapping in
            mapping.prefixes.contains { lowercased.hasPrefix($0) }
        }) else {
            return .plain
        }

        return match.tokenType
    }

    /// Sorts tokens by position and removes overlapping tokens.
    static func deduplicateAndSort(_ tokens: [HighlightToken]) -> [HighlightToken] {
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

    /// Renders highlight tokens to HTML with span elements.
    static func renderTokensToHTML(code: String, tokens: [HighlightToken]) -> String {
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
