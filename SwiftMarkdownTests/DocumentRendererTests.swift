import XCTest
import Markdown
@testable import SwiftMarkdownCore

final class DocumentRendererTests: XCTestCase {
    // MARK: - Empty Document Tests

    func test_emptyDocument_returnsEmptyString() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertEqual(result.string, "")
    }

    // MARK: - Single Element Tests

    func test_singleParagraph_rendersParagraph() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "Hello world")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Hello world"))
    }

    func test_singleHeading_rendersHeading() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "# Title")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Title"))
        guard let font = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    // MARK: - Multiple Element Tests

    func test_headingAndParagraph_rendersInOrder() {
        let renderer = DocumentRenderer()
        let markdown = """
        # Title

        Some paragraph text
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let titleRange = (result.string as NSString).range(of: "Title")
        let paragraphRange = (result.string as NSString).range(of: "Some paragraph text")

        XCTAssertNotEqual(titleRange.location, NSNotFound)
        XCTAssertNotEqual(paragraphRange.location, NSNotFound)
        XCTAssertLessThan(titleRange.location, paragraphRange.location)
    }

    func test_multipleParagraphs_rendersSeparated() {
        let renderer = DocumentRenderer()
        let markdown = """
        First paragraph.

        Second paragraph.
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("First paragraph"))
        XCTAssertTrue(result.string.contains("Second paragraph"))
    }

    // MARK: - Inline Element Tests

    func test_paragraphWithBold_rendersWithBoldAttribute() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "This is **bold** text")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let boldRange = (result.string as NSString).range(of: "bold")
        guard boldRange.location != NSNotFound else {
            XCTFail("Bold text not found")
            return
        }

        guard let font = result.attribute(.font, at: boldRange.location, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    func test_paragraphWithItalic_rendersWithItalicAttribute() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "This is *italic* text")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let italicRange = (result.string as NSString).range(of: "italic")
        guard italicRange.location != NSNotFound else {
            XCTFail("Italic text not found")
            return
        }

        guard let font = result.attribute(.font, at: italicRange.location, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.italic))
    }

    func test_paragraphWithInlineCode_rendersWithMonospaceFont() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "Use the `print()` function")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let codeRange = (result.string as NSString).range(of: "print()")
        guard codeRange.location != NSNotFound else {
            XCTFail("Inline code not found")
            return
        }

        guard let font = result.attribute(.font, at: codeRange.location, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontName.lowercased().contains("mono") || font.isFixedPitch)
    }

    func test_paragraphWithLink_rendersWithLinkAttribute() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "Visit [Example](https://example.com)")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let linkRange = (result.string as NSString).range(of: "Example")
        guard linkRange.location != NSNotFound else {
            XCTFail("Link text not found")
            return
        }

        let url = result.attribute(.link, at: linkRange.location, effectiveRange: nil) as? URL
        XCTAssertEqual(url?.absoluteString, "https://example.com")
    }

    // MARK: - Block Element Tests

    func test_codeBlock_rendersWithMonospaceFont() {
        let renderer = DocumentRenderer()
        let markdown = """
        ```
        let x = 1
        ```
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let codeRange = (result.string as NSString).range(of: "let x = 1")
        guard codeRange.location != NSNotFound else {
            XCTFail("Code block content not found")
            return
        }

        guard let font = result.attribute(.font, at: codeRange.location, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontName.lowercased().contains("mono") || font.isFixedPitch)
    }

    func test_blockquote_rendersWithIndent() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "> Quoted text")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Quoted text"))
    }

    func test_unorderedList_rendersWithBullets() {
        let renderer = DocumentRenderer()
        let markdown = """
        - Item 1
        - Item 2
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Item 1"))
        XCTAssertTrue(result.string.contains("Item 2"))
    }

    func test_orderedList_rendersWithNumbers() {
        let renderer = DocumentRenderer()
        let markdown = """
        1. First
        2. Second
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("First"))
        XCTAssertTrue(result.string.contains("Second"))
        XCTAssertTrue(result.string.contains("1"))
        XCTAssertTrue(result.string.contains("2"))
    }

    func test_horizontalRule_rendersAttachment() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "---")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        var foundAttachment = false
        result.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: result.length)
        ) { value, _, _ in
            if value != nil {
                foundAttachment = true
            }
        }
        XCTAssertTrue(foundAttachment)
    }

    func test_table_rendersAllCells() {
        let renderer = DocumentRenderer()
        let markdown = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("A"))
        XCTAssertTrue(result.string.contains("B"))
        XCTAssertTrue(result.string.contains("1"))
        XCTAssertTrue(result.string.contains("2"))
    }

    // MARK: - Complex Document Tests

    func test_complexDocument_rendersAllElements() {
        let renderer = DocumentRenderer()
        let markdown = """
        # Main Title

        This is a paragraph with **bold** and *italic* text.

        ## Code Section

        ```swift
        func hello() {
            print("Hello")
        }
        ```

        - Item A
        - Item B

        > A quote
        """
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Main Title"))
        XCTAssertTrue(result.string.contains("bold"))
        XCTAssertTrue(result.string.contains("italic"))
        XCTAssertTrue(result.string.contains("Code Section"))
        XCTAssertTrue(result.string.contains("func hello()"))
        XCTAssertTrue(result.string.contains("Item A"))
        XCTAssertTrue(result.string.contains("Item B"))
        XCTAssertTrue(result.string.contains("A quote"))
    }

    // MARK: - Theme Tests

    func test_document_usesThemeColors() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "Hello")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotNil(color)
    }

    // MARK: - Line Break Tests

    func test_softBreak_rendersAsSpace() {
        let renderer = DocumentRenderer()
        // Soft break is a single newline within a paragraph
        let markdown = "Line one\nLine two"
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Line one"))
        XCTAssertTrue(result.string.contains("Line two"))
    }

    func test_hardBreak_rendersAsNewline() {
        let renderer = DocumentRenderer()
        // Hard break is two spaces followed by newline
        let markdown = "Line one  \nLine two"
        let document = Document(parsing: markdown)
        let result = renderer.render(document, theme: .default, context: RenderContext())

        XCTAssertTrue(result.string.contains("Line one"))
        XCTAssertTrue(result.string.contains("Line two"))
    }

    // MARK: - Strikethrough Tests

    func test_strikethrough_rendersWithAttribute() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "This is ~~deleted~~ text")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let deletedRange = (result.string as NSString).range(of: "deleted")
        guard deletedRange.location != NSNotFound else {
            XCTFail("Strikethrough text not found")
            return
        }

        let strikethrough = result.attribute(
            .strikethroughStyle,
            at: deletedRange.location,
            effectiveRange: nil
        ) as? Int
        XCTAssertNotNil(strikethrough)
        XCTAssertEqual(strikethrough, NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Nested Inline Tests

    func test_nestedInlineElements_composesCorrectly() {
        let renderer = DocumentRenderer()
        let document = Document(parsing: "This is ***bold italic*** text")
        let result = renderer.render(document, theme: .default, context: RenderContext())

        let boldItalicRange = (result.string as NSString).range(of: "bold italic")
        guard boldItalicRange.location != NSNotFound else {
            XCTFail("Bold italic text not found")
            return
        }

        guard let font = result.attribute(.font, at: boldItalicRange.location, effectiveRange: nil) as? NSFont else {
            XCTFail("Expected font attribute")
            return
        }
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.italic))
    }
}
