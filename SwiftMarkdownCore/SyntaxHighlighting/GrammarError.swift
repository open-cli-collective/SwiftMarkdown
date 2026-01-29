import Foundation

/// Errors that can occur during grammar operations.
public enum GrammarError: Error, LocalizedError, Equatable {
    /// The requested grammar is not available in the manifest.
    case unknownGrammar(String)

    /// Failed to download the grammar from the remote server.
    case downloadFailed(String, String)

    /// Failed to extract the grammar tarball.
    case extractionFailed(String, String)

    /// Failed to load the dynamic library.
    case loadFailed(String, String)

    /// The tree_sitter_<lang> symbol was not found in the library.
    case symbolNotFound(String)

    /// Failed to create the cache directory.
    case cacheDirectoryError(String)

    /// Failed to parse the manifest.
    case manifestParseError(String)

    /// Network error during download.
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .unknownGrammar(let language):
            return "Unknown grammar: \(language)"
        case .downloadFailed(let language, let reason):
            return "Failed to download \(language) grammar: \(reason)"
        case .extractionFailed(let language, let reason):
            return "Failed to extract \(language) grammar: \(reason)"
        case .loadFailed(let language, let reason):
            return "Failed to load \(language) grammar: \(reason)"
        case .symbolNotFound(let symbol):
            return "Symbol not found: \(symbol)"
        case .cacheDirectoryError(let reason):
            return "Cache directory error: \(reason)"
        case .manifestParseError(let reason):
            return "Failed to parse manifest: \(reason)"
        case .networkError(let reason):
            return "Network error: \(reason)"
        }
    }
}
