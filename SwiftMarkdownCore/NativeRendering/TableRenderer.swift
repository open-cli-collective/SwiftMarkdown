import AppKit

/// Renders markdown tables to NSAttributedString using NSTextTable.
///
/// Tables are rendered using AppKit's `NSTextTable` and `NSTextTableBlock` APIs,
/// which keep everything within the attributed string and preserve text selection.
///
/// ## Example
/// ```swift
/// let renderer = TableRenderer()
/// let headers = [NSAttributedString(string: "Name"), NSAttributedString(string: "Value")]
/// let rows = [[NSAttributedString(string: "foo"), NSAttributedString(string: "42")]]
/// let result = renderer.render(
///     TableRenderer.Input(headers: headers, rows: rows),
///     theme: .default,
///     context: RenderContext()
/// )
/// ```
public struct TableRenderer: MarkdownElementRenderer {
    /// Column alignment options.
    public enum Alignment {
        case left
        case center
        case right

        fileprivate var textAlignment: NSTextAlignment {
            switch self {
            case .left: return .left
            case .center: return .center
            case .right: return .right
            }
        }
    }

    /// Input for table rendering.
    public struct Input {
        /// Header cells.
        public let headers: [NSAttributedString]
        /// Data rows, each containing cells.
        public let rows: [[NSAttributedString]]
        /// Column alignments (defaults to left for all).
        public let alignments: [Alignment]

        public init(
            headers: [NSAttributedString],
            rows: [[NSAttributedString]],
            alignments: [Alignment]? = nil
        ) {
            self.headers = headers
            self.rows = rows
            self.alignments = alignments ?? Array(repeating: .left, count: headers.count)
        }
    }

    /// Internal struct to group cell rendering parameters.
    private struct CellConfig {
        let content: NSAttributedString
        let table: NSTextTable
        let row: Int
        let column: Int
        let isHeader: Bool
        let alignment: Alignment
    }

    public init() {}

    public func render(_ input: Input, theme: MarkdownTheme, context: RenderContext) -> NSAttributedString {
        let columnCount = input.headers.count

        // Handle empty table
        guard columnCount > 0 else {
            return NSAttributedString(string: "\n")
        }

        let result = NSMutableAttributedString()

        // Create the table
        let table = NSTextTable()
        table.numberOfColumns = columnCount
        table.collapsesBorders = true

        // Render header row
        for (colIndex, header) in input.headers.enumerated() {
            let config = CellConfig(
                content: header,
                table: table,
                row: 0,
                column: colIndex,
                isHeader: true,
                alignment: alignment(for: colIndex, in: input)
            )
            result.append(renderCell(config, theme: theme))
        }

        // Render data rows
        for (rowIndex, row) in input.rows.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                let config = CellConfig(
                    content: cell,
                    table: table,
                    row: rowIndex + 1, // +1 for header row
                    column: colIndex,
                    isHeader: false,
                    alignment: alignment(for: colIndex, in: input)
                )
                result.append(renderCell(config, theme: theme))
            }
        }

        return result
    }

    private func renderCell(_ config: CellConfig, theme: MarkdownTheme) -> NSAttributedString {
        // Create the table block for this cell
        let block = NSTextTableBlock(
            table: config.table,
            startingRow: config.row,
            rowSpan: 1,
            startingColumn: config.column,
            columnSpan: 1
        )

        // Style the block
        block.setWidth(0.5, type: .absoluteValueType, for: .border)
        block.setBorderColor(.separatorColor)
        block.setContentWidth(100, type: .percentageValueType)

        if config.isHeader {
            block.backgroundColor = NSColor.windowBackgroundColor
        }

        // Set padding
        block.setWidth(4, type: .absoluteValueType, for: .padding)

        // Create paragraph style with the table block
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textBlocks = [block]
        paragraphStyle.alignment = config.alignment.textAlignment

        // Build the cell string (must end with newline for NSTextTable)
        let cellString = NSMutableAttributedString(attributedString: config.content)
        cellString.append(NSAttributedString(string: "\n"))

        // Apply attributes
        let fullRange = NSRange(location: 0, length: cellString.length)
        cellString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        let font = config.isHeader ? theme.headingFont(level: 6) : theme.bodyFont
        cellString.addAttribute(.font, value: font, range: fullRange)
        cellString.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)

        return cellString
    }

    private func alignment(for column: Int, in input: Input) -> Alignment {
        guard column < input.alignments.count else {
            return .left
        }
        return input.alignments[column]
    }
}
