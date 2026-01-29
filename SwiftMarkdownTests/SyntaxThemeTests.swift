import XCTest
@testable import SwiftMarkdownCore

final class SyntaxThemeTests: XCTestCase {
    // MARK: - CSS Variable Tests

    func testCSSContainsVariables() {
        let css = SyntaxTheme.default.generateCSS()

        XCTAssertTrue(css.contains("--syntax-keyword"))
        XCTAssertTrue(css.contains("--syntax-string"))
        XCTAssertTrue(css.contains("--syntax-comment"))
        XCTAssertTrue(css.contains("--syntax-number"))
        XCTAssertTrue(css.contains("--syntax-function"))
        XCTAssertTrue(css.contains("--syntax-type"))
        XCTAssertTrue(css.contains("--syntax-variable"))
        XCTAssertTrue(css.contains("--syntax-operator"))
        XCTAssertTrue(css.contains("--syntax-punctuation"))
        XCTAssertTrue(css.contains("--syntax-property"))
        XCTAssertTrue(css.contains("--syntax-attribute"))
    }

    func testCSSContainsDarkModeMediaQuery() {
        let css = SyntaxTheme.default.generateCSS()

        XCTAssertTrue(css.contains("prefers-color-scheme: dark"))
    }

    func testCSSContainsTokenClasses() {
        let css = SyntaxTheme.default.generateCSS()

        XCTAssertTrue(css.contains(".token-keyword"))
        XCTAssertTrue(css.contains(".token-string"))
        XCTAssertTrue(css.contains(".token-comment"))
        XCTAssertTrue(css.contains(".token-number"))
        XCTAssertTrue(css.contains(".token-function"))
        XCTAssertTrue(css.contains(".token-type"))
        XCTAssertTrue(css.contains(".token-variable"))
        XCTAssertTrue(css.contains(".token-operator"))
        XCTAssertTrue(css.contains(".token-punctuation"))
        XCTAssertTrue(css.contains(".token-property"))
        XCTAssertTrue(css.contains(".token-attribute"))
    }

    func testCSSTokenClassesUseVariables() {
        let css = SyntaxTheme.default.generateCSS()

        XCTAssertTrue(css.contains(".token-keyword { color: var(--syntax-keyword)"))
        XCTAssertTrue(css.contains(".token-string { color: var(--syntax-string)"))
    }

    func testCommentHasItalicStyle() {
        let css = SyntaxTheme.default.generateCSS()

        XCTAssertTrue(css.contains(".token-comment { color: var(--syntax-comment); font-style: italic; }"))
    }

    // MARK: - Color Preset Tests

    func testLightColorsPreset() {
        let colors = SyntaxColors.light

        XCTAssertEqual(colors.keyword, "#af00db")
        XCTAssertEqual(colors.string, "#a31515")
        XCTAssertEqual(colors.comment, "#008000")
        XCTAssertEqual(colors.number, "#098658")
        XCTAssertEqual(colors.function, "#795e26")
        XCTAssertEqual(colors.type, "#267f99")
        XCTAssertEqual(colors.variable, "#001080")
    }

    func testDarkColorsPreset() {
        let colors = SyntaxColors.dark

        XCTAssertEqual(colors.keyword, "#c586c0")
        XCTAssertEqual(colors.string, "#ce9178")
        XCTAssertEqual(colors.comment, "#6a9955")
        XCTAssertEqual(colors.number, "#b5cea8")
        XCTAssertEqual(colors.function, "#dcdcaa")
        XCTAssertEqual(colors.type, "#4ec9b0")
        XCTAssertEqual(colors.variable, "#9cdcfe")
    }

    // MARK: - Custom Theme Tests

    func testCustomThemeGeneratesValidCSS() {
        var theme = SyntaxTheme.default
        theme.light.keyword = "#ff0000"
        theme.dark.keyword = "#00ff00"

        let css = theme.generateCSS()

        XCTAssertTrue(css.contains("#ff0000"))
        XCTAssertTrue(css.contains("#00ff00"))
    }

    func testCustomColorsAreUsed() {
        let customLight = SyntaxColors(
            keyword: "#111111",
            string: "#222222",
            comment: "#333333",
            number: "#444444",
            function: "#555555",
            type: "#666666",
            variable: "#777777",
            operator: "#888888",
            punctuation: "#999999",
            property: "#aaaaaa",
            attribute: "#bbbbbb"
        )

        let theme = SyntaxTheme(light: customLight, dark: .dark)
        let css = theme.generateCSS()

        XCTAssertTrue(css.contains("--syntax-keyword: #111111"))
        XCTAssertTrue(css.contains("--syntax-string: #222222"))
        XCTAssertTrue(css.contains("--syntax-comment: #333333"))
    }

    // MARK: - HTMLRenderer CSS Tests

    func testHTMLRendererReturnsCSS() {
        let renderer = HTMLRenderer()

        XCTAssertFalse(renderer.cssStyles.isEmpty)
    }

    func testHTMLRendererCSSContainsTokenClasses() {
        let renderer = HTMLRenderer()
        let css = renderer.cssStyles

        XCTAssertTrue(css.contains(".token-keyword"))
        XCTAssertTrue(css.contains(".token-string"))
    }

    func testHTMLRendererCSSContainsDarkMode() {
        let renderer = HTMLRenderer()
        let css = renderer.cssStyles

        XCTAssertTrue(css.contains("prefers-color-scheme: dark"))
    }

    func testHTMLRendererWrapInDocumentIncludesCSS() {
        let renderer = HTMLRenderer(wrapInDocument: true)
        let document = MarkdownParser.parseDocument("# Hello")
        let html = renderer.render(document)

        XCTAssertTrue(html.contains("<style>"))
        XCTAssertTrue(html.contains("</style>"))
        XCTAssertTrue(html.contains(".token-keyword"))
    }

    // MARK: - Equality Tests

    func testSyntaxColorsEquality() {
        let colors1 = SyntaxColors.light
        let colors2 = SyntaxColors.light

        XCTAssertEqual(colors1, colors2)
    }

    func testSyntaxColorsInequality() {
        var colors1 = SyntaxColors.light
        var colors2 = SyntaxColors.light
        colors2.keyword = "#ffffff"

        XCTAssertNotEqual(colors1, colors2)
    }

    func testSyntaxThemeEquality() {
        let theme1 = SyntaxTheme.default
        let theme2 = SyntaxTheme.default

        XCTAssertEqual(theme1, theme2)
    }

    func testSyntaxThemeInequality() {
        var theme1 = SyntaxTheme.default
        var theme2 = SyntaxTheme.default
        theme2.light.keyword = "#ffffff"

        XCTAssertNotEqual(theme1, theme2)
    }
}
