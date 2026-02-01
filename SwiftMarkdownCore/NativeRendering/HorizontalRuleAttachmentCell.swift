import AppKit

/// A text attachment cell that draws a horizontal rule line.
///
/// This cell renders a thin horizontal line that spans most of its width,
/// used for markdown horizontal rules (---).
final class HorizontalRuleAttachmentCell: NSTextAttachmentCell {
    private let lineColor: NSColor
    private let lineThickness: CGFloat

    /// Creates a horizontal rule attachment cell.
    ///
    /// - Parameters:
    ///   - color: The color of the line.
    ///   - thickness: The thickness of the line in points.
    init(color: NSColor, thickness: CGFloat = 1.0) {
        self.lineColor = color
        self.lineThickness = thickness
        super.init()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cellSize() -> NSSize {
        // Height includes some padding around the line
        NSSize(width: 100, height: 16)
    }

    override func cellBaselineOffset() -> NSPoint {
        NSPoint(x: 0, y: -4)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        lineColor.setFill()

        // Draw a horizontal line centered vertically in the cell
        let lineY = cellFrame.midY - lineThickness / 2
        let lineRect = NSRect(
            x: cellFrame.minX,
            y: lineY,
            width: cellFrame.width,
            height: lineThickness
        )
        lineRect.fill()
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?, characterIndex charIndex: Int) {
        draw(withFrame: cellFrame, in: controlView)
    }

    override func draw(
        withFrame cellFrame: NSRect,
        in controlView: NSView?,
        characterIndex charIndex: Int,
        layoutManager: NSLayoutManager
    ) {
        draw(withFrame: cellFrame, in: controlView)
    }
}
