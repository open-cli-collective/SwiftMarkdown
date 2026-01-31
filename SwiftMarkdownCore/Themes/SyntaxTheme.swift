import Foundation

/// Defines colors for syntax highlighting tokens.
///
/// Use the static `.light` and `.dark` presets for standard themes,
/// or create custom themes with your own colors.
public struct SyntaxColors: Equatable, Sendable {
    public var keyword: String
    public var string: String
    public var comment: String
    public var number: String
    public var function: String
    public var type: String
    public var variable: String
    public var `operator`: String
    public var punctuation: String
    public var property: String
    public var attribute: String

    public init(
        keyword: String,
        string: String,
        comment: String,
        number: String,
        function: String,
        type: String,
        variable: String,
        operator: String,
        punctuation: String,
        property: String,
        attribute: String
    ) {
        self.keyword = keyword
        self.string = string
        self.comment = comment
        self.number = number
        self.function = function
        self.type = type
        self.variable = variable
        self.operator = `operator`
        self.punctuation = punctuation
        self.property = property
        self.attribute = attribute
    }

    /// Light theme colors inspired by VS Code Light+.
    public static let light = SyntaxColors(
        keyword: "#af00db",
        string: "#a31515",
        comment: "#008000",
        number: "#098658",
        function: "#795e26",
        type: "#267f99",
        variable: "#001080",
        operator: "#000000",
        punctuation: "#000000",
        property: "#001080",
        attribute: "#795e26"
    )

    /// Dark theme colors inspired by VS Code Dark+.
    public static let dark = SyntaxColors(
        keyword: "#c586c0",
        string: "#ce9178",
        comment: "#6a9955",
        number: "#b5cea8",
        function: "#dcdcaa",
        type: "#4ec9b0",
        variable: "#9cdcfe",
        operator: "#d4d4d4",
        punctuation: "#d4d4d4",
        property: "#9cdcfe",
        attribute: "#dcdcaa"
    )
}

/// A theme for syntax highlighting with light and dark mode support.
///
/// Themes are defined using CSS custom properties (variables) which enables
/// automatic light/dark mode switching via `prefers-color-scheme` media query.
///
/// ## Example
/// ```swift
/// let theme = SyntaxTheme.default
/// let css = theme.generateCSS()
/// // Use css in your HTML document
/// ```
public struct SyntaxTheme: Equatable, Sendable {
    /// Colors for light mode.
    public var light: SyntaxColors

    /// Colors for dark mode.
    public var dark: SyntaxColors

    public init(light: SyntaxColors, dark: SyntaxColors) {
        self.light = light
        self.dark = dark
    }

    /// The default theme with VS Code-inspired light and dark colors.
    public static let `default` = SyntaxTheme(light: .light, dark: .dark)

    /// Base document styling CSS for light/dark mode support (GitHub colors).
    private static let documentCSS = """
        html { color-scheme: light dark; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            font-size: 16px; line-height: 1.6; color: #1f2328; background-color: #ffffff;
            padding: 24px 32px; max-width: 900px; margin: 0 auto;
        }
        @media (prefers-color-scheme: dark) { body { color: #d1d7e0; background-color: #212830; } }
        h1, h2, h3, h4, h5, h6 { margin-top: 24px; margin-bottom: 16px; font-weight: 600; }
        a { color: #0969da; text-decoration: none; }
        a:hover { text-decoration: underline; }
        @media (prefers-color-scheme: dark) { a { color: #478be6; } }
        pre {
            background-color: #f6f8fa; border-radius: 6px; padding: 16px; overflow-x: auto;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: 14px;
        }
        @media (prefers-color-scheme: dark) { pre { background-color: #262c36; } }
        code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
        """

    /// Token class CSS definitions.
    private static let tokenClassesCSS = """
        .token-keyword { color: var(--syntax-keyword); }
        .token-string { color: var(--syntax-string); }
        .token-comment { color: var(--syntax-comment); font-style: italic; }
        .token-number { color: var(--syntax-number); }
        .token-function { color: var(--syntax-function); }
        .token-type { color: var(--syntax-type); }
        .token-variable { color: var(--syntax-variable); }
        .token-operator { color: var(--syntax-operator); }
        .token-punctuation { color: var(--syntax-punctuation); }
        .token-property { color: var(--syntax-property); }
        .token-attribute { color: var(--syntax-attribute); }
        """

    /// Generates CSS with custom properties for both light and dark modes.
    ///
    /// The generated CSS includes:
    /// - Document base styling (body, headings, links, etc.)
    /// - CSS variables in `:root` for light mode (default)
    /// - CSS variables in `@media (prefers-color-scheme: dark)` for dark mode
    /// - Token classes that reference the CSS variables
    ///
    /// - Returns: A CSS string ready to be embedded in an HTML document.
    public func generateCSS() -> String {
        let lightVars = generateVariables(from: light)
        let darkVars = generateVariables(from: dark)

        return """
        \(Self.documentCSS)
        :root { \(lightVars) }
        @media (prefers-color-scheme: dark) { :root { \(darkVars) } }
        \(Self.tokenClassesCSS)
        """
    }

    private func generateVariables(from colors: SyntaxColors) -> String {
        """
        --syntax-keyword: \(colors.keyword); --syntax-string: \(colors.string); \
        --syntax-comment: \(colors.comment); --syntax-number: \(colors.number); \
        --syntax-function: \(colors.function); --syntax-type: \(colors.type); \
        --syntax-variable: \(colors.variable); --syntax-operator: \(colors.operator); \
        --syntax-punctuation: \(colors.punctuation); --syntax-property: \(colors.property); \
        --syntax-attribute: \(colors.attribute);
        """
    }
}
