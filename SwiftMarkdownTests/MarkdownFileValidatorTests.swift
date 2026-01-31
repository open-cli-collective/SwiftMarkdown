import XCTest
@testable import SwiftMarkdownCore

final class MarkdownFileValidatorTests: XCTestCase {
    // MARK: - isMarkdownFile Tests

    func testIsMarkdownFileWithMdExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.md")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMarkdownExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.markdown")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMdownExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mdown")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMkdnExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mkdn")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileWithMkdExtension() {
        let url = URL(fileURLWithPath: "/path/to/file.mkd")
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileIsCaseInsensitive() {
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/FILE.MD")))
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/File.Markdown")))
        XCTAssertTrue(MarkdownFileValidator.isMarkdownFile(URL(fileURLWithPath: "/path/to/README.MDOWN")))
    }

    func testIsMarkdownFileReturnsFalseForTextFile() {
        let url = URL(fileURLWithPath: "/path/to/file.txt")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForHtmlFile() {
        let url = URL(fileURLWithPath: "/path/to/file.html")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForPdfFile() {
        let url = URL(fileURLWithPath: "/path/to/document.pdf")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForNoExtension() {
        let url = URL(fileURLWithPath: "/path/to/README")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    func testIsMarkdownFileReturnsFalseForSimilarExtension() {
        // .mdx is not in the supported list
        let url = URL(fileURLWithPath: "/path/to/file.mdx")
        XCTAssertFalse(MarkdownFileValidator.isMarkdownFile(url))
    }

    // MARK: - supportedExtensions Tests

    func testSupportedExtensionsContainsExpectedValues() {
        let expected: Set<String> = ["md", "markdown", "mdown", "mkdn", "mkd"]
        XCTAssertEqual(MarkdownFileValidator.supportedExtensions, expected)
    }
}
