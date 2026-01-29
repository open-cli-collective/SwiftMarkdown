import XCTest
@testable import SwiftMarkdownCore

final class SyntaxHighlighterTests: XCTestCase {
    // MARK: - TreeSitterHighlighter Basic Tests

    func testSupportsSwiftLanguage() {
        let highlighter = TreeSitterHighlighter()
        XCTAssertTrue(highlighter.supportsLanguage("swift"))
        XCTAssertTrue(highlighter.supportsLanguage("Swift"))
        XCTAssertTrue(highlighter.supportsLanguage("SWIFT"))
    }

    func testDoesNotSupportUnsupportedLanguage() {
        let highlighter = TreeSitterHighlighter()
        XCTAssertFalse(highlighter.supportsLanguage("brainfuck"))
        XCTAssertFalse(highlighter.supportsLanguage("cobol"))
        XCTAssertFalse(highlighter.supportsLanguage(""))
    }

    func testSupportedLanguagesList() {
        let highlighter = TreeSitterHighlighter()
        XCTAssertTrue(highlighter.supportedLanguages.contains("swift"))
    }

    // MARK: - Token Extraction Tests

    func testSwiftHighlightingProducesTokens() {
        let highlighter = TreeSitterHighlighter()
        let tokens = highlighter.highlight(code: "let x = 1", language: "swift")

        // Should produce some tokens for basic Swift code
        XCTAssertFalse(tokens.isEmpty, "Should produce tokens for valid Swift code")
    }

    func testSwiftHighlightingIdentifiesKeyword() {
        let highlighter = TreeSitterHighlighter()
        let tokens = highlighter.highlight(code: "let x = 1", language: "swift")

        // Should identify 'let' as a keyword
        let hasKeyword = tokens.contains { $0.tokenType == .keyword }
        XCTAssertTrue(hasKeyword, "Should identify 'let' as a keyword")
    }

    func testUnsupportedLanguageReturnsEmptyTokens() {
        let highlighter = TreeSitterHighlighter()
        let tokens = highlighter.highlight(code: "some code", language: "brainfuck")

        XCTAssertTrue(tokens.isEmpty, "Should return empty tokens for unsupported language")
    }

    func testEmptyCodeReturnsEmptyTokens() {
        let highlighter = TreeSitterHighlighter()
        let tokens = highlighter.highlight(code: "", language: "swift")

        XCTAssertTrue(tokens.isEmpty, "Should return empty tokens for empty code")
    }

    // MARK: - HTML Output Tests

    func testHighlightToHTMLProducesSpanElements() {
        let highlighter = TreeSitterHighlighter()
        let html = highlighter.highlightToHTML(code: "let x = 1", language: "swift")

        // Should contain span elements for tokens
        XCTAssertTrue(html.contains("<span class=\"token-"), "Should contain token span elements")
    }

    func testHighlightToHTMLContainsKeywordSpan() {
        let highlighter = TreeSitterHighlighter()
        let html = highlighter.highlightToHTML(code: "let x = 1", language: "swift")

        XCTAssertTrue(html.contains("token-keyword"), "Should contain keyword token class")
    }

    func testHighlightToHTMLEscapesSpecialCharacters() {
        let highlighter = TreeSitterHighlighter()
        let html = highlighter.highlightToHTML(code: "let x = \"<script>\"", language: "swift")

        // Should escape HTML special characters (< and > get escaped even if tokens are fragmented)
        XCTAssertTrue(html.contains("&lt;"), "Should escape < character")
        XCTAssertTrue(html.contains("&gt;"), "Should escape > character")
        // The literal unescaped <script> tag should not appear
        XCTAssertFalse(html.contains("<script>"), "Should not contain unescaped HTML tags")
    }

    func testUnsupportedLanguageFallsBackToEscapedHTML() {
        let highlighter = TreeSitterHighlighter()
        let html = highlighter.highlightToHTML(code: "<script>alert('xss')</script>", language: "unknown")

        // Should escape the code but not add highlighting
        XCTAssertTrue(html.contains("&lt;script&gt;"), "Should escape HTML")
        XCTAssertFalse(html.contains("<span class=\"token-"), "Should not contain token spans")
    }

    // MARK: - HTMLRenderer Integration Tests

    func testHTMLRendererWithHighlighter() {
        let highlighter = TreeSitterHighlighter()
        let renderer = HTMLRenderer(syntaxHighlighter: highlighter)
        let document = MarkdownParser.parseDocument("""
            ```swift
            let greeting = "Hello"
            ```
            """)

        let html = renderer.render(document)

        XCTAssertTrue(html.contains("language-swift"), "Should have language class")
        XCTAssertTrue(html.contains("token-keyword"), "Should have highlighted keywords")
    }

    func testHTMLRendererWithoutHighlighter() {
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument("""
            ```swift
            let greeting = "Hello"
            ```
            """)

        let html = renderer.render(document)

        XCTAssertTrue(html.contains("language-swift"), "Should have language class")
        XCTAssertFalse(html.contains("token-"), "Should not have token spans without highlighter")
    }

    func testHTMLRendererWithUnsupportedLanguage() {
        let highlighter = TreeSitterHighlighter()
        let renderer = HTMLRenderer(syntaxHighlighter: highlighter)
        let document = MarkdownParser.parseDocument("""
            ```python
            print("Hello")
            ```
            """)

        let html = renderer.render(document)

        // Should render code but without highlighting (Python not yet supported)
        XCTAssertTrue(html.contains("language-python"), "Should have language class")
        XCTAssertFalse(html.contains("token-"), "Should not have token spans for unsupported language")
    }

    // MARK: - MarkdownParser Integration Tests

    func testParseWithHighlighting() {
        let md = """
            # Code Example

            ```swift
            let x = 1
            ```
            """

        let html = MarkdownParser.parseWithHighlighting(md)

        XCTAssertTrue(html.contains("<h1>Code Example</h1>"), "Should render heading")
        XCTAssertTrue(html.contains("token-keyword"), "Should have highlighted keywords")
    }

    func testParseWithHighlightingMixedContent() {
        let md = """
            Some text with `inline code` and:

            ```swift
            func hello() {
                print("Hello")
            }
            ```

            And more text.
            """

        let html = MarkdownParser.parseWithHighlighting(md)

        // Inline code should not be highlighted
        XCTAssertTrue(html.contains("<code>inline code</code>"), "Inline code should not be highlighted")

        // Fenced code block should be highlighted
        XCTAssertTrue(html.contains("token-keyword"), "Fenced code should have highlighting")
    }

    // MARK: - Token Type Tests

    func testTokenTypeRawValues() {
        // Verify token types have expected raw values for CSS class generation
        XCTAssertEqual(HighlightToken.TokenType.keyword.rawValue, "keyword")
        XCTAssertEqual(HighlightToken.TokenType.string.rawValue, "string")
        XCTAssertEqual(HighlightToken.TokenType.comment.rawValue, "comment")
        XCTAssertEqual(HighlightToken.TokenType.number.rawValue, "number")
        XCTAssertEqual(HighlightToken.TokenType.function.rawValue, "function")
        XCTAssertEqual(HighlightToken.TokenType.type.rawValue, "type")
        XCTAssertEqual(HighlightToken.TokenType.variable.rawValue, "variable")
        XCTAssertEqual(HighlightToken.TokenType.operator.rawValue, "operator")
        XCTAssertEqual(HighlightToken.TokenType.punctuation.rawValue, "punctuation")
        XCTAssertEqual(HighlightToken.TokenType.property.rawValue, "property")
        XCTAssertEqual(HighlightToken.TokenType.attribute.rawValue, "attribute")
        XCTAssertEqual(HighlightToken.TokenType.plain.rawValue, "plain")
    }

    func testAllTokenTypesCovered() {
        // Ensure all cases are tested
        XCTAssertEqual(HighlightToken.TokenType.allCases.count, 12)
    }

    // MARK: - Complex Swift Code Tests

    func testComplexSwiftCodeHighlighting() {
        let highlighter = TreeSitterHighlighter()
        let code = """
            struct Person {
                let name: String
                var age: Int

                func greet() -> String {
                    return "Hello, \\(name)"
                }
            }
            """

        let tokens = highlighter.highlight(code: code, language: "swift")

        // Should have multiple tokens for complex code
        XCTAssertGreaterThan(tokens.count, 5, "Complex code should produce multiple tokens")

        // Should identify struct keyword
        let hasStructKeyword = tokens.contains { $0.tokenType == .keyword }
        XCTAssertTrue(hasStructKeyword, "Should identify keywords in complex code")
    }
}
