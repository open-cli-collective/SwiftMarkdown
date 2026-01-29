import XCTest
@testable import SwiftMarkdownCore

final class HTMLRendererTests: XCTestCase {
    // MARK: - Renderer Compatibility

    func testHTMLRendererMatchesLegacyAPI() {
        let markdown = "# Hello **World**"
        let legacy = MarkdownParser.parse(markdown)
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let rendered = renderer.render(document)
        XCTAssertEqual(legacy, rendered)
    }

    func testHTMLRendererMatchesLegacyWithComplexMarkdown() {
        let markdown = """
        # Header

        A paragraph with **bold** and *italic*.

        - Item 1
        - Item 2

        ```swift
        let x = 1
        ```
        """
        let legacy = MarkdownParser.parse(markdown)
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let rendered = renderer.render(document)
        XCTAssertEqual(legacy, rendered)
    }

    // MARK: - Custom Renderer API

    func testCustomRendererAPI() {
        let renderer = HTMLRenderer()
        let html = MarkdownParser.parse("# Test", renderer: renderer)
        XCTAssertTrue(html.contains("<h1>"))
    }

    func testCustomRendererAPIWithOptions() {
        let renderer = HTMLRenderer()
        let html = MarkdownParser.parse("# Test", renderer: renderer, options: .all)
        XCTAssertTrue(html.contains("<h1>"))
    }

    // MARK: - Document Wrapping

    func testWrapInDocumentFalse() {
        let renderer = HTMLRenderer(wrapInDocument: false)
        let document = MarkdownParser.parseDocument("# Hello")
        let html = renderer.render(document)
        XCTAssertFalse(html.contains("<!DOCTYPE html>"))
        XCTAssertFalse(html.contains("<html>"))
        XCTAssertFalse(html.contains("<body>"))
    }

    func testWrapInDocumentTrue() {
        var renderer = HTMLRenderer()
        renderer.wrapInDocument = true
        let document = MarkdownParser.parseDocument("# Hello")
        let html = renderer.render(document)
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<html>"))
        XCTAssertTrue(html.contains("<body>"))
        XCTAssertTrue(html.contains("<h1>Hello</h1>"))
        XCTAssertTrue(html.contains("</body>"))
        XCTAssertTrue(html.contains("</html>"))
    }

    func testWrapInDocumentInitializer() {
        let renderer = HTMLRenderer(wrapInDocument: true)
        let document = MarkdownParser.parseDocument("Hello")
        let html = renderer.render(document)
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }

    // MARK: - CSS Styles Property

    func testCSSStylesProperty() {
        let renderer = HTMLRenderer()
        // Currently returns empty string; will be populated with themes
        XCTAssertNotNil(renderer.cssStyles)
    }

    // MARK: - All Element Types

    func testRendersAllBasicElements() {
        let markdown = """
        # Heading 1
        ## Heading 2

        Paragraph with **bold**, *italic*, and ~~strikethrough~~.

        > Blockquote

        ---

        - List item

        1. Ordered item

        [Link](https://example.com)

        ![Image](image.png)

        `inline code`

        ```
        code block
        ```
        """
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("<h1>"))
        XCTAssertTrue(html.contains("<h2>"))
        XCTAssertTrue(html.contains("<p>"))
        XCTAssertTrue(html.contains("<strong>"))
        XCTAssertTrue(html.contains("<em>"))
        XCTAssertTrue(html.contains("<del>"))
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("<hr>"))
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<a href="))
        XCTAssertTrue(html.contains("<img src="))
        XCTAssertTrue(html.contains("<code>"))
        XCTAssertTrue(html.contains("<pre>"))
    }

    func testRendersTable() {
        let markdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<th>"))
        XCTAssertTrue(html.contains("<td>"))
    }

    func testRendersTaskList() {
        let markdown = """
        - [x] Checked
        - [ ] Unchecked
        """
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("<input type=\"checkbox\" disabled checked>"))
        XCTAssertTrue(html.contains("<input type=\"checkbox\" disabled>"))
    }

    // MARK: - HTML Escaping

    func testHTMLEscaping() {
        // Test escaping of special characters in regular text
        let markdown = "5 > 3 and 2 < 4 and A & B"
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("&gt;"), "Greater than should be escaped")
        XCTAssertTrue(html.contains("&lt;"), "Less than should be escaped")
        XCTAssertTrue(html.contains("&amp;"), "Ampersand should be escaped")
    }

    func testHTMLEscapingInCodeBlock() {
        let markdown = """
        ```
        <script>alert('test')</script>
        ```
        """
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("<script>alert"))
    }

    func testHTMLEscapingInLinks() {
        let markdown = "[Click & Go](https://example.com?a=1&b=2)"
        let renderer = HTMLRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("&amp;"), "Ampersand in text should be escaped")
    }
}
