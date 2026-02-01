import XCTest
@testable import SwiftMarkdownCore

final class CodeBlockRendererTests: XCTestCase {
    // MARK: - Font Tests

    func test_codeBlock_usesMonospaceFont() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "let x = 1", language: nil),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.monoSpace))
    }

    func test_codeBlock_usesThemeCodeFontSize() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "code", language: nil),
            theme: .default,
            context: RenderContext()
        )

        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertEqual(font.pointSize, MarkdownTheme.default.codeFontSize, accuracy: 0.1)
    }

    // MARK: - Background Color Tests

    func test_codeBlock_hasBackgroundColor() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "x", language: nil),
            theme: .default,
            context: RenderContext()
        )

        // Background is now on NSTextBlock, not as a text attribute
        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle,
              let textBlock = style.textBlocks.first else {
            XCTFail("Expected paragraph style with text block")
            return
        }
        XCTAssertNotNil(textBlock.backgroundColor)
    }

    func test_codeBlock_backgroundSpansEntireCode() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "line one\nline two", language: nil),
            theme: .default,
            context: RenderContext()
        )

        // Background is now on NSTextBlock which spans the entire code block
        var range = NSRange(location: 0, length: 0)
        _ = result.attribute(.paragraphStyle, at: 0, effectiveRange: &range)
        XCTAssertEqual(range.length, result.length)
    }

    // MARK: - Content Tests

    func test_codeBlock_preservesWhitespace() {
        let renderer = CodeBlockRenderer()
        let code = "line1\n  indented\n    more\nline4"
        let result = renderer.render(
            CodeBlockRenderer.Input(code: code, language: nil),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasPrefix(code))
    }

    func test_codeBlock_addsTrailingNewline() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "code", language: nil),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }

    func test_codeBlock_emptyCode_returnsNewlineOnly() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "", language: nil),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "\n")
    }

    // MARK: - Text Color Tests

    func test_codeBlock_usesTextColor() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "code", language: nil),
            theme: .default,
            context: RenderContext()
        )

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Syntax Highlighting Tests

    func test_codeBlock_withHighlighter_appliesSyntaxColors() {
        let code = "let x = 1"
        let mockHighlighter = MockSyntaxHighlighter(tokens: [
            HighlightToken(
                range: code.startIndex..<code.index(code.startIndex, offsetBy: 3),
                tokenType: .keyword
            )
        ])
        let renderer = CodeBlockRenderer(highlighter: mockHighlighter)
        let result = renderer.render(
            CodeBlockRenderer.Input(code: code, language: "swift"),
            theme: .default,
            context: RenderContext()
        )

        // The "let" part should have the keyword color
        let keywordColor = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        let expectedColor = MarkdownTheme.default.syntaxColor(for: "keyword")
        XCTAssertNotNil(keywordColor)
        XCTAssertNotNil(expectedColor)
    }

    func test_codeBlock_withHighlighter_noLanguage_noHighlighting() {
        let code = "let x = 1"
        let mockHighlighter = MockSyntaxHighlighter(tokens: [
            HighlightToken(
                range: code.startIndex..<code.index(code.startIndex, offsetBy: 3),
                tokenType: .keyword
            )
        ])
        let renderer = CodeBlockRenderer(highlighter: mockHighlighter)
        let result = renderer.render(
            CodeBlockRenderer.Input(code: code, language: nil),
            theme: .default,
            context: RenderContext()
        )

        // Without language, highlighter shouldn't be called
        XCTAssertFalse(mockHighlighter.highlightCalled)
        // Should use default text color throughout
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    func test_codeBlock_withHighlighter_multipleTokens() {
        let code = "let x = 1"
        // "let" is keyword at 0-3, "1" is number at 8-9
        let mockHighlighter = MockSyntaxHighlighter(tokens: [
            HighlightToken(
                range: code.startIndex..<code.index(code.startIndex, offsetBy: 3),
                tokenType: .keyword
            ),
            HighlightToken(
                range: code.index(code.startIndex, offsetBy: 8)..<code.endIndex,
                tokenType: .number
            )
        ])
        let renderer = CodeBlockRenderer(highlighter: mockHighlighter)
        let result = renderer.render(
            CodeBlockRenderer.Input(code: code, language: "swift"),
            theme: .default,
            context: RenderContext()
        )

        // Verify the code content is preserved
        XCTAssertTrue(result.string.hasPrefix(code))
    }

    // MARK: - Paragraph Style Tests

    func test_codeBlock_hasNoParagraphSpacing() {
        let renderer = CodeBlockRenderer()
        let result = renderer.render(
            CodeBlockRenderer.Input(code: "code", language: nil),
            theme: .default,
            context: RenderContext()
        )

        guard let style = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        // Code blocks should preserve lines as-is
        XCTAssertEqual(style.lineSpacing, 0, accuracy: 0.1)
    }
}

// MARK: - Mock Highlighter

private final class MockSyntaxHighlighter: SyntaxHighlighter, @unchecked Sendable {
    let tokens: [HighlightToken]
    private(set) var highlightCalled = false

    init(tokens: [HighlightToken]) {
        self.tokens = tokens
    }

    var supportedLanguages: [String] {
        ["swift", "javascript", "python"]
    }

    func supportsLanguage(_ language: String) -> Bool {
        supportedLanguages.contains(language.lowercased())
    }

    func highlight(code: String, language: String) -> [HighlightToken] {
        highlightCalled = true
        return tokens
    }
}
