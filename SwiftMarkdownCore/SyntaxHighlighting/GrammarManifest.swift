import Foundation

/// Metadata about a single grammar in the manifest.
public struct GrammarInfo: Codable, Equatable, Sendable {
    /// Display name for the language (e.g., "JavaScript").
    public let displayName: String

    /// Version of the grammar (e.g., "v0.23.1").
    public let version: String

    /// License type (e.g., "MIT", "Apache-2.0").
    public let license: String

    /// Alternative names for the language (e.g., ["js", "jsx"]).
    public let aliases: [String]

    /// SHA-256 checksum of the dylib file.
    public let checksum: String

    /// Size of the dylib file in bytes.
    public let size: Int
}

/// Parsed manifest from apple-tree-sitter-grammars releases.
///
/// The manifest contains metadata about all available grammars,
/// including their versions, checksums, and aliases.
public struct GrammarManifest: Codable, Equatable, Sendable {
    /// Manifest schema version.
    public let version: String

    /// When the manifest was generated.
    public let generatedAt: String

    /// Grammar metadata keyed by canonical name.
    public let grammars: [String: GrammarInfo]

    /// Maps a language identifier to its canonical grammar name.
    ///
    /// Handles aliases like "js" -> "javascript", "py" -> "python".
    /// Returns nil if the language is not found.
    public func canonicalName(for language: String) -> String? {
        let lowercased = language.lowercased()

        // Direct match
        if grammars[lowercased] != nil {
            return lowercased
        }

        // Search aliases
        for (name, info) in grammars where info.aliases.map({ $0.lowercased() }).contains(lowercased) {
            return name
        }

        return nil
    }

    /// Returns the grammar info for a language, resolving aliases.
    public func grammarInfo(for language: String) -> GrammarInfo? {
        guard let canonical = canonicalName(for: language) else {
            return nil
        }
        return grammars[canonical]
    }

    /// All supported language identifiers (canonical names + aliases).
    public var supportedLanguages: [String] {
        var languages: [String] = []
        for (name, info) in grammars {
            languages.append(name)
            languages.append(contentsOf: info.aliases)
        }
        return languages.sorted()
    }

    /// Parses a manifest from JSON data.
    public static func parse(from data: Data) throws -> GrammarManifest {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(GrammarManifest.self, from: data)
        } catch {
            throw GrammarError.manifestParseError(error.localizedDescription)
        }
    }

    /// Parses a manifest from a JSON string.
    public static func parse(from string: String) throws -> GrammarManifest {
        guard let data = string.data(using: .utf8) else {
            throw GrammarError.manifestParseError("Invalid UTF-8 string")
        }
        return try parse(from: data)
    }
}
