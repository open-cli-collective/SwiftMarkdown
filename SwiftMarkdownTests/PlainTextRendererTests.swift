import XCTest
@testable import SwiftMarkdownCore

final class PlainTextRendererTests: XCTestCase {
    // MARK: - Basic Rendering

    func testPlainTextRenderer() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("# Hello **World**")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("Hello"))
        XCTAssertTrue(text.contains("World"))
        XCTAssertFalse(text.contains("<"))
    }

    func testPlainTextRendererMatchesLegacyAPI() {
        let markdown = "# Hello **World**"
        let legacy = MarkdownParser.parse(markdown, format: .plainText)
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let rendered = renderer.render(document)
        XCTAssertEqual(legacy, rendered)
    }

    // MARK: - Custom Renderer API

    func testCustomRendererAPI() {
        let renderer = PlainTextRenderer()
        let text = MarkdownParser.parse("# Test", renderer: renderer)
        XCTAssertTrue(text.contains("Test"))
        XCTAssertFalse(text.contains("<"))
    }

    // MARK: - Text Extraction

    func testStripsEmphasis() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("This is *emphasized* text.")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("emphasized"))
        XCTAssertFalse(text.contains("*"))
    }

    func testStripsStrong() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("This is **strong** text.")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("strong"))
        XCTAssertFalse(text.contains("**"))
    }

    func testStripsStrikethrough() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("This is ~~deleted~~ text.")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("deleted"))
        XCTAssertFalse(text.contains("~~"))
    }

    // MARK: - Lists

    func testUnorderedListWithBullets() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("""
        - Item 1
        - Item 2
        """)
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("•"))
        XCTAssertTrue(text.contains("Item 1"))
        XCTAssertTrue(text.contains("Item 2"))
    }

    func testOrderedListRendered() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("""
        1. First
        2. Second
        """)
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("First"))
        XCTAssertTrue(text.contains("Second"))
    }

    // MARK: - Code

    func testInlineCodePreserved() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("Use `code` here.")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("code"))
        XCTAssertFalse(text.contains("`"))
    }

    func testCodeBlockPreserved() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("""
        ```swift
        let x = 1
        ```
        """)
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("let x = 1"))
        XCTAssertFalse(text.contains("```"))
    }

    // MARK: - Links and Images

    func testLinkTextExtracted() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("[Example](https://example.com)")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("Example"))
        XCTAssertFalse(text.contains("https://"))
        XCTAssertFalse(text.contains("["))
    }

    func testImageAltTextExtracted() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("![Alt text](image.png)")
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("Alt text"))
        XCTAssertFalse(text.contains("image.png"))
    }

    // MARK: - Tables

    func testTableRendered() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("""
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """)
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("Header 1"))
        XCTAssertTrue(text.contains("Header 2"))
        XCTAssertTrue(text.contains("Cell 1"))
        XCTAssertTrue(text.contains("Cell 2"))
        XCTAssertFalse(text.contains("|"))
        XCTAssertFalse(text.contains("-"))
    }

    // MARK: - Thematic Break

    func testThematicBreakRendered() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("""
        Above

        ---

        Below
        """)
        let text = renderer.render(document)
        XCTAssertTrue(text.contains("---"))
        XCTAssertTrue(text.contains("Above"))
        XCTAssertTrue(text.contains("Below"))
    }

    // MARK: - HTML Stripping

    func testHTMLBlockStripped() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("<div>HTML content</div>")
        let text = renderer.render(document)
        // HTML blocks are stripped in plain text output
        XCTAssertFalse(text.contains("<div>"))
    }

    func testInlineHTMLStripped() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("Text with <em>inline</em> HTML")
        let text = renderer.render(document)
        // Inline HTML is stripped
        XCTAssertFalse(text.contains("<em>"))
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument("")
        let text = renderer.render(document)
        XCTAssertEqual(text, "")
    }

    func testComplexDocument() {
        let markdown = """
        # Title

        A paragraph with **bold** and *italic*.

        > Blockquote text

        - List item 1
        - List item 2

        ```
        code
        ```
        """
        let renderer = PlainTextRenderer()
        let document = MarkdownParser.parseDocument(markdown)
        let text = renderer.render(document)

        XCTAssertTrue(text.contains("Title"))
        XCTAssertTrue(text.contains("bold"))
        XCTAssertTrue(text.contains("italic"))
        XCTAssertTrue(text.contains("Blockquote text"))
        XCTAssertTrue(text.contains("List item 1"))
        XCTAssertTrue(text.contains("code"))
        XCTAssertFalse(text.contains("<"))
        XCTAssertFalse(text.contains("**"))
        XCTAssertFalse(text.contains("*"))
    }
}
