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

    /// Generates CSS with custom properties for both light and dark modes.
    ///
    /// The generated CSS includes:
    /// - CSS variables in `:root` for light mode (default)
    /// - CSS variables in `@media (prefers-color-scheme: dark)` for dark mode
    /// - Token classes that reference the CSS variables
    ///
    /// - Returns: A CSS string ready to be embedded in an HTML document.
    public func generateCSS() -> String {
        """
        :root {
            --syntax-keyword: \(light.keyword);
            --syntax-string: \(light.string);
            --syntax-comment: \(light.comment);
            --syntax-number: \(light.number);
            --syntax-function: \(light.function);
            --syntax-type: \(light.type);
            --syntax-variable: \(light.variable);
            --syntax-operator: \(light.operator);
            --syntax-punctuation: \(light.punctuation);
            --syntax-property: \(light.property);
            --syntax-attribute: \(light.attribute);
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --syntax-keyword: \(dark.keyword);
                --syntax-string: \(dark.string);
                --syntax-comment: \(dark.comment);
                --syntax-number: \(dark.number);
                --syntax-function: \(dark.function);
                --syntax-type: \(dark.type);
                --syntax-variable: \(dark.variable);
                --syntax-operator: \(dark.operator);
                --syntax-punctuation: \(dark.punctuation);
                --syntax-property: \(dark.property);
                --syntax-attribute: \(dark.attribute);
            }
        }

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
    }
}
