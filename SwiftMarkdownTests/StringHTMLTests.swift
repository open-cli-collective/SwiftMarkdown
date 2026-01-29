import XCTest
@testable import SwiftMarkdownCore

final class StringHTMLTests: XCTestCase {
    func testEscapesAmpersand() {
        XCTAssertEqual("foo & bar".htmlEscaped, "foo &amp; bar")
    }

    func testEscapesLessThan() {
        XCTAssertEqual("a < b".htmlEscaped, "a &lt; b")
    }

    func testEscapesGreaterThan() {
        XCTAssertEqual("a > b".htmlEscaped, "a &gt; b")
    }

    func testEscapesQuotes() {
        XCTAssertEqual("say \"hello\"".htmlEscaped, "say &quot;hello&quot;")
    }

    func testEscapesAllSpecialCharacters() {
        let input = "<script>alert(\"XSS & stuff\")</script>"
        let expected = "&lt;script&gt;alert(&quot;XSS &amp; stuff&quot;)&lt;/script&gt;"
        XCTAssertEqual(input.htmlEscaped, expected)
    }

    func testEmptyString() {
        XCTAssertEqual("".htmlEscaped, "")
    }

    func testNoSpecialCharacters() {
        XCTAssertEqual("hello world".htmlEscaped, "hello world")
    }

    func testAmpersandFirst() {
        // Verify & is escaped first (before other replacements could create &)
        XCTAssertEqual("&lt;".htmlEscaped, "&amp;lt;")
    }
}
