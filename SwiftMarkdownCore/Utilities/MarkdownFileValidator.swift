import Foundation

/// Utilities for validating markdown files.
public enum MarkdownFileValidator {
    /// Supported file extensions for markdown files.
    public static let supportedExtensions: Set<String> = ["md", "markdown", "mdown", "mkdn", "mkd"]

    /// Check if a URL points to a valid markdown file based on extension.
    public static func isMarkdownFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }
}
