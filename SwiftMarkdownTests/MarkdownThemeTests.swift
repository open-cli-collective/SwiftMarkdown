import XCTest
@testable import SwiftMarkdownCore

final class MarkdownThemeTests: XCTestCase {
    // MARK: - Heading Fonts

    func test_headingFont_level1_hasLargestSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 1)
        XCTAssertEqual(font.pointSize, 28, accuracy: 0.1)
    }

    func test_headingFont_level2_hasSmallerSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 2)
        XCTAssertEqual(font.pointSize, 24, accuracy: 0.1)
    }

    func test_headingFont_level3_hasSmallerSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 3)
        XCTAssertEqual(font.pointSize, 20, accuracy: 0.1)
    }

    func test_headingFont_level4_hasSmallerSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 4)
        XCTAssertEqual(font.pointSize, 18, accuracy: 0.1)
    }

    func test_headingFont_level5_hasSmallerSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 5)
        XCTAssertEqual(font.pointSize, 16, accuracy: 0.1)
    }

    func test_headingFont_level6_hasSmallestSize() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 6)
        XCTAssertEqual(font.pointSize, 14, accuracy: 0.1)
    }

    func test_headingFont_isBold() {
        let theme = MarkdownTheme.default
        let font = theme.headingFont(level: 1)
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.bold))
    }

    func test_headingFont_outOfRangeLevel_clampsToValidRange() {
        let theme = MarkdownTheme.default
        // Level 0 should clamp to level 1
        XCTAssertEqual(theme.headingFont(level: 0).pointSize, theme.headingFont(level: 1).pointSize, accuracy: 0.1)
        // Level 7 should clamp to level 6
        XCTAssertEqual(theme.headingFont(level: 7).pointSize, theme.headingFont(level: 6).pointSize, accuracy: 0.1)
    }

    // MARK: - Body Font

    func test_bodyFont_hasExpectedSize() {
        let theme = MarkdownTheme.default
        XCTAssertEqual(theme.bodyFont.pointSize, 16, accuracy: 0.1)
    }

    // MARK: - Code Font

    func test_codeFont_isMonospace() {
        let theme = MarkdownTheme.default
        XCTAssertTrue(theme.codeFont.fontDescriptor.symbolicTraits.contains(.monoSpace))
    }

    func test_codeFont_hasExpectedSize() {
        let theme = MarkdownTheme.default
        XCTAssertEqual(theme.codeFont.pointSize, 14, accuracy: 0.1)
    }

    // MARK: - Code Block Background

    func test_codeBlockBackground_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.codeBlockBackground)
    }

    // MARK: - Syntax Colors

    func test_syntaxColor_keyword_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "keyword"))
    }

    func test_syntaxColor_string_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "string"))
    }

    func test_syntaxColor_comment_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "comment"))
    }

    func test_syntaxColor_number_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "number"))
    }

    func test_syntaxColor_function_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "function"))
    }

    func test_syntaxColor_type_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColor(for: "type"))
    }

    func test_syntaxColor_unknown_returnsNil() {
        let theme = MarkdownTheme.default
        XCTAssertNil(theme.syntaxColor(for: "nonexistent_capture_name"))
    }

    func test_syntaxColor_qualifiedName_fallsBackToBaseName() {
        let theme = MarkdownTheme.default
        // "keyword.control" should fall back to "keyword"
        let qualifiedColor = theme.syntaxColor(for: "keyword.control")
        let baseColor = theme.syntaxColor(for: "keyword")
        XCTAssertNotNil(qualifiedColor)
        XCTAssertEqual(qualifiedColor, baseColor)
    }

    func test_syntaxColor_qualifiedName_withUnknownBase_returnsNil() {
        let theme = MarkdownTheme.default
        XCTAssertNil(theme.syntaxColor(for: "unknown.qualified.name"))
    }

    // MARK: - Spacing

    func test_paragraphSpacing_hasPositiveValue() {
        let theme = MarkdownTheme.default
        XCTAssertGreaterThan(theme.paragraphSpacing, 0)
    }

    func test_listIndent_hasPositiveValue() {
        let theme = MarkdownTheme.default
        XCTAssertGreaterThan(theme.listIndent, 0)
    }

    func test_blockquoteIndent_hasPositiveValue() {
        let theme = MarkdownTheme.default
        XCTAssertGreaterThan(theme.blockquoteIndent, 0)
    }

    // MARK: - Link Color

    func test_linkColor_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.linkColor)
    }

    // MARK: - Blockquote Color

    func test_blockquoteColor_exists() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.blockquoteColor)
    }
}
