import XCTest
@testable import SwiftMarkdownCore

final class MarkdownParserTests: XCTestCase {
    // MARK: - Basic Markdown

    func testHeading() {
        let markdown = "# Hello World"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<h1>Hello World</h1>"))
    }

    func testMultipleLevelHeadings() {
        let markdown = """
        # H1
        ## H2
        ### H3
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<h1>H1</h1>"))
        XCTAssertTrue(html.contains("<h2>H2</h2>"))
        XCTAssertTrue(html.contains("<h3>H3</h3>"))
    }

    func testParagraph() {
        let markdown = "This is a paragraph."
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<p>This is a paragraph.</p>"))
    }

    func testEmphasis() {
        let markdown = "This is *emphasized* text."
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<em>emphasized</em>"))
    }

    func testStrong() {
        let markdown = "This is **strong** text."
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<strong>strong</strong>"))
    }

    func testInlineCode() {
        let markdown = "Use `let x = 1` for assignment."
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<code>let x = 1</code>"))
    }

    // MARK: - GFM Extensions

    func testStrikethrough() {
        let markdown = "This is ~~deleted~~ text."
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<del>deleted</del>"))
    }

    func testTable() {
        let markdown = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        | Bob | 25 |
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<th>Name</th>"))
        XCTAssertTrue(html.contains("<th>Age</th>"))
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<td>Alice</td>"))
        XCTAssertTrue(html.contains("<td>30</td>"))
    }

    func testTaskListChecked() {
        let markdown = "- [x] Completed task"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<input type=\"checkbox\" disabled checked>"))
    }

    func testTaskListUnchecked() {
        let markdown = "- [ ] Pending task"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<input type=\"checkbox\" disabled>"))
        XCTAssertFalse(html.contains("checked"))
    }

    // MARK: - Code Blocks

    func testFencedCodeBlockWithLanguage() {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">"))
        XCTAssertTrue(html.contains("let x = 1"))
    }

    func testFencedCodeBlockWithoutLanguage() {
        let markdown = """
        ```
        plain code
        ```
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<pre><code>"))
        XCTAssertTrue(html.contains("plain code"))
    }

    // MARK: - Links and Images

    func testLink() {
        let markdown = "[Example](https://example.com)"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">Example</a>"))
    }

    func testImage() {
        let markdown = "![Alt text](https://example.com/image.png)"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<img src=\"https://example.com/image.png\" alt=\"Alt text\">"))
    }

    // MARK: - Lists

    func testUnorderedList() {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>Item 1</li>"))
        XCTAssertTrue(html.contains("<li>Item 2</li>"))
        XCTAssertTrue(html.contains("<li>Item 3</li>"))
        XCTAssertTrue(html.contains("</ul>"))
    }

    func testOrderedList() {
        let markdown = """
        1. First
        2. Second
        3. Third
        """
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>First</li>"))
        XCTAssertTrue(html.contains("<li>Second</li>"))
        XCTAssertTrue(html.contains("<li>Third</li>"))
        XCTAssertTrue(html.contains("</ol>"))
    }

    // MARK: - Block Elements

    func testBlockQuote() {
        let markdown = "> This is a quote"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("This is a quote"))
        XCTAssertTrue(html.contains("</blockquote>"))
    }

    func testThematicBreak() {
        let markdown = "---"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("<hr>"))
    }

    // MARK: - HTML Escaping

    func testHTMLEscaping() {
        // Test that special characters in text are escaped
        let markdown = "5 > 3 and 2 < 4 and A & B"
        let html = MarkdownParser.parse(markdown)
        XCTAssertTrue(html.contains("&gt;"), "Greater than should be escaped")
        XCTAssertTrue(html.contains("&lt;"), "Less than should be escaped")
        XCTAssertTrue(html.contains("&amp;"), "Ampersand should be escaped")
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let html = MarkdownParser.parse("")
        XCTAssertEqual(html, "")
    }

    func testWhitespaceOnlyInput() {
        let html = MarkdownParser.parse("   ")
        XCTAssertTrue(html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      html.contains("<p>"))
    }

    // MARK: - Plain Text Output

    func testPlainTextOutput() {
        let markdown = "# Hello **World**"
        let text = MarkdownParser.parse(markdown, format: .plainText)
        XCTAssertTrue(text.contains("Hello"))
        XCTAssertTrue(text.contains("World"))
        XCTAssertFalse(text.contains("<"))
        XCTAssertFalse(text.contains("**"))
    }

    // MARK: - Document API

    func testParseDocument() {
        let markdown = "# Title\n\nParagraph"
        let document = MarkdownParser.parseDocument(markdown)
        XCTAssertFalse(document.isEmpty)
    }
}
