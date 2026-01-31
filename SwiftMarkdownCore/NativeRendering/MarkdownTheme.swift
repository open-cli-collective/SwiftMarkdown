import AppKit

/// Theme configuration for native NSAttributedString-based markdown rendering.
///
/// Provides fonts, colors, and spacing for all markdown element types.
/// Uses semantic colors for automatic light/dark mode support.
///
/// ## Example
/// ```swift
/// let theme = MarkdownTheme.default
/// let headingFont = theme.headingFont(level: 1)  // 28pt bold
/// let keywordColor = theme.syntaxColor(for: "keyword")
/// ```
public struct MarkdownTheme: Sendable {
    // MARK: - Font Sizes

    /// Font sizes for heading levels 1-6.
    public let headingFontSizes: [CGFloat]

    /// Body text font size.
    public let bodyFontSize: CGFloat

    /// Code font size.
    public let codeFontSize: CGFloat

    // MARK: - Colors

    /// Text color (semantic, adapts to light/dark mode).
    public let textColor: NSColor

    /// Link color.
    public let linkColor: NSColor

    /// Blockquote text color.
    public let blockquoteColor: NSColor

    /// Code block background color.
    public let codeBlockBackground: NSColor

    /// Inline code background color.
    public let inlineCodeBackground: NSColor

    /// Syntax highlighting colors keyed by capture name.
    public let syntaxColors: [String: NSColor]

    // MARK: - Spacing

    /// Spacing between paragraphs.
    public let paragraphSpacing: CGFloat

    /// Indentation for list items.
    public let listIndent: CGFloat

    /// Indentation for blockquotes.
    public let blockquoteIndent: CGFloat

    /// Line spacing multiplier.
    public let lineSpacing: CGFloat

    // MARK: - Initialization

    public init(
        headingFontSizes: [CGFloat] = [28, 24, 20, 18, 16, 14],
        bodyFontSize: CGFloat = 16,
        codeFontSize: CGFloat = 14,
        textColor: NSColor = .labelColor,
        linkColor: NSColor = .linkColor,
        blockquoteColor: NSColor = .secondaryLabelColor,
        codeBlockBackground: NSColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(white: 0.15, alpha: 1.0)
                : NSColor(white: 0.96, alpha: 1.0)
        },
        inlineCodeBackground: NSColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(white: 0.2, alpha: 1.0)
                : NSColor(white: 0.94, alpha: 1.0)
        },
        syntaxColors: [String: NSColor] = Self.defaultSyntaxColors,
        paragraphSpacing: CGFloat = 12,
        listIndent: CGFloat = 24,
        blockquoteIndent: CGFloat = 16,
        lineSpacing: CGFloat = 1.4
    ) {
        self.headingFontSizes = headingFontSizes
        self.bodyFontSize = bodyFontSize
        self.codeFontSize = codeFontSize
        self.textColor = textColor
        self.linkColor = linkColor
        self.blockquoteColor = blockquoteColor
        self.codeBlockBackground = codeBlockBackground
        self.inlineCodeBackground = inlineCodeBackground
        self.syntaxColors = syntaxColors
        self.paragraphSpacing = paragraphSpacing
        self.listIndent = listIndent
        self.blockquoteIndent = blockquoteIndent
        self.lineSpacing = lineSpacing
    }

    // MARK: - Default Theme

    /// The default theme with GitHub-inspired styling.
    public static let `default` = MarkdownTheme()

    // MARK: - Font Accessors

    /// Returns the font for a heading at the specified level (1-6).
    ///
    /// Levels outside the 1-6 range are clamped to the nearest valid level.
    public func headingFont(level: Int) -> NSFont {
        let clampedLevel = max(1, min(6, level))
        let size = headingFontSizes[clampedLevel - 1]
        return NSFont.boldSystemFont(ofSize: size)
    }

    /// The body text font.
    public var bodyFont: NSFont {
        NSFont.systemFont(ofSize: bodyFontSize)
    }

    /// The monospace font for code.
    public var codeFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular)
    }

    // MARK: - Syntax Color Accessor

    /// Returns the color for a syntax highlighting capture name.
    ///
    /// - Parameter captureName: The Tree-sitter capture name (e.g., "keyword", "string").
    /// - Returns: The color for the capture, or nil if not defined.
    public func syntaxColor(for captureName: String) -> NSColor? {
        // Handle qualified names like "keyword.control" -> try "keyword.control" then "keyword"
        if let color = syntaxColors[captureName] {
            return color
        }
        // Fall back to base name
        let baseName = captureName.components(separatedBy: ".").first ?? captureName
        return syntaxColors[baseName]
    }

    // MARK: - Default Syntax Colors

    /// Default syntax colors that adapt to light/dark mode.
    public static let defaultSyntaxColors: [String: NSColor] = [
        "keyword": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.77, green: 0.52, blue: 0.75, alpha: 1.0)  // #c586c0
                : NSColor(red: 0.69, green: 0.0, blue: 0.86, alpha: 1.0)   // #af00db
        },
        "string": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.81, green: 0.57, blue: 0.47, alpha: 1.0)  // #ce9178
                : NSColor(red: 0.64, green: 0.08, blue: 0.08, alpha: 1.0)  // #a31515
        },
        "comment": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.42, green: 0.60, blue: 0.33, alpha: 1.0)  // #6a9955
                : NSColor(red: 0.0, green: 0.50, blue: 0.0, alpha: 1.0)    // #008000
        },
        "number": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.71, green: 0.81, blue: 0.66, alpha: 1.0)  // #b5cea8
                : NSColor(red: 0.04, green: 0.53, blue: 0.34, alpha: 1.0)  // #098658
        },
        "function": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.86, green: 0.86, blue: 0.67, alpha: 1.0)  // #dcdcaa
                : NSColor(red: 0.47, green: 0.37, blue: 0.15, alpha: 1.0)  // #795e26
        },
        "type": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.31, green: 0.79, blue: 0.69, alpha: 1.0)  // #4ec9b0
                : NSColor(red: 0.15, green: 0.50, blue: 0.60, alpha: 1.0)  // #267f99
        },
        "variable": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.61, green: 0.86, blue: 0.99, alpha: 1.0)  // #9cdcfe
                : NSColor(red: 0.0, green: 0.06, blue: 0.50, alpha: 1.0)   // #001080
        },
        "operator": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1.0)  // #d4d4d4
                : NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)     // #000000
        },
        "punctuation": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 1.0)  // #d4d4d4
                : NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)     // #000000
        },
        "property": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.61, green: 0.86, blue: 0.99, alpha: 1.0)  // #9cdcfe
                : NSColor(red: 0.0, green: 0.06, blue: 0.50, alpha: 1.0)   // #001080
        },
        "attribute": NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.86, green: 0.86, blue: 0.67, alpha: 1.0)  // #dcdcaa
                : NSColor(red: 0.47, green: 0.37, blue: 0.15, alpha: 1.0)  // #795e26
        }
    ]
}
