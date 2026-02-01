import XCTest
@testable import SwiftMarkdownCore

final class TableRendererTests: XCTestCase {
    // MARK: - Content Tests

    func test_table_rendersAllCells() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "A"), NSAttributedString(string: "B")]
        let rows = [
            [NSAttributedString(string: "1"), NSAttributedString(string: "2")],
            [NSAttributedString(string: "3"), NSAttributedString(string: "4")]
        ]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("A"))
        XCTAssertTrue(result.string.contains("B"))
        XCTAssertTrue(result.string.contains("1"))
        XCTAssertTrue(result.string.contains("4"))
    }

    func test_table_singleColumn() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Header")]
        let rows = [[NSAttributedString(string: "Cell")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("Header"))
        XCTAssertTrue(result.string.contains("Cell"))
    }

    func test_table_multipleRows() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Col")]
        let rows = [
            [NSAttributedString(string: "Row1")],
            [NSAttributedString(string: "Row2")],
            [NSAttributedString(string: "Row3")]
        ]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("Row1"))
        XCTAssertTrue(result.string.contains("Row2"))
        XCTAssertTrue(result.string.contains("Row3"))
    }

    // MARK: - Structure Tests

    func test_table_hasTextTableBlocks() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "A")]
        let rows = [[NSAttributedString(string: "1")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        var foundTableBlock = false
        result.enumerateAttribute(
            .paragraphStyle,
            in: NSRange(location: 0, length: result.length)
        ) { value, _, _ in
            if let style = value as? NSParagraphStyle,
               let block = style.textBlocks.first as? NSTextTableBlock {
                foundTableBlock = true
                _ = block // Silence warning
            }
        }
        XCTAssertTrue(foundTableBlock)
    }

    func test_table_correctColumnCount() {
        let renderer = TableRenderer()
        let headers = [
            NSAttributedString(string: "A"),
            NSAttributedString(string: "B"),
            NSAttributedString(string: "C")
        ]
        let rows = [[
            NSAttributedString(string: "1"),
            NSAttributedString(string: "2"),
            NSAttributedString(string: "3")
        ]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        var maxColumn = -1
        result.enumerateAttribute(
            .paragraphStyle,
            in: NSRange(location: 0, length: result.length)
        ) { value, _, _ in
            if let style = value as? NSParagraphStyle,
               let block = style.textBlocks.first as? NSTextTableBlock {
                maxColumn = max(maxColumn, block.startingColumn)
            }
        }
        XCTAssertEqual(maxColumn, 2) // 0-indexed, 3 columns = max index 2
    }

    // MARK: - Header Tests

    func test_table_headerRowHasBackground() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Header")]
        let rows = [[NSAttributedString(string: "Cell")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        let headerRange = (result.string as NSString).range(of: "Header")
        guard headerRange.location != NSNotFound else {
            XCTFail("Header not found")
            return
        }

        guard let style = result.attribute(.paragraphStyle, at: headerRange.location, effectiveRange: nil) as? NSParagraphStyle,
              let block = style.textBlocks.first as? NSTextTableBlock else {
            XCTFail("Expected table block")
            return
        }

        XCTAssertNotNil(block.backgroundColor)
    }

    // MARK: - Alignment Tests

    func test_table_leftAlignment() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Left")]
        let rows = [[NSAttributedString(string: "text")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows, alignments: [.left]),
            theme: .default,
            context: RenderContext()
        )

        let textRange = (result.string as NSString).range(of: "text")
        guard textRange.location != NSNotFound else {
            XCTFail("Text not found")
            return
        }

        guard let style = result.attribute(.paragraphStyle, at: textRange.location, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertEqual(style.alignment, .left)
    }

    func test_table_centerAlignment() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Center")]
        let rows = [[NSAttributedString(string: "text")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows, alignments: [.center]),
            theme: .default,
            context: RenderContext()
        )

        let textRange = (result.string as NSString).range(of: "text")
        guard textRange.location != NSNotFound else {
            XCTFail("Text not found")
            return
        }

        guard let style = result.attribute(.paragraphStyle, at: textRange.location, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertEqual(style.alignment, .center)
    }

    func test_table_rightAlignment() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "Right")]
        let rows = [[NSAttributedString(string: "text")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows, alignments: [.right]),
            theme: .default,
            context: RenderContext()
        )

        let textRange = (result.string as NSString).range(of: "text")
        guard textRange.location != NSNotFound else {
            XCTFail("Text not found")
            return
        }

        guard let style = result.attribute(.paragraphStyle, at: textRange.location, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("Expected paragraph style")
            return
        }
        XCTAssertEqual(style.alignment, .right)
    }

    // MARK: - Edge Cases

    func test_table_emptyTable_returnsNewline() {
        let renderer = TableRenderer()
        let headers: [NSAttributedString] = []
        let rows: [[NSAttributedString]] = []
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertEqual(result.string, "\n")
    }

    func test_table_headersOnly_noRows() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "A"), NSAttributedString(string: "B")]
        let rows: [[NSAttributedString]] = []
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.contains("A"))
        XCTAssertTrue(result.string.contains("B"))
    }

    func test_table_addsTrailingNewline() {
        let renderer = TableRenderer()
        let headers = [NSAttributedString(string: "H")]
        let rows = [[NSAttributedString(string: "C")]]
        let result = renderer.render(
            TableRenderer.Input(headers: headers, rows: rows),
            theme: .default,
            context: RenderContext()
        )

        XCTAssertTrue(result.string.hasSuffix("\n"))
    }
}
