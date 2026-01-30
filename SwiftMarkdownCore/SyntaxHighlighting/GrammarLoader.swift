import Foundation
import SwiftTreeSitter

/// A stateless utility for synchronously loading grammars from disk.
///
/// This enum provides shared grammar loading logic used by both `TreeSitterHighlighter`
/// and `LazyTreeSitterHighlighter`. It checks Homebrew and cache directories for
/// installed grammars and loads them via dlopen.
///
/// ## Usage
/// ```swift
/// if let grammar = GrammarLoader.loadGrammarSync("javascript", cacheURL: cacheDir) {
///     // Use grammar.language with tree-sitter
/// }
/// ```
enum GrammarLoader {
    /// Default Homebrew prefixes to check for grammars.
    static let homebrewPrefixes = ["/opt/homebrew", "/usr/local"]

    /// Synchronously loads a grammar from Homebrew or cache directories.
    ///
    /// Checks Homebrew directories first (Apple Silicon, then Intel), followed by
    /// the application cache directory.
    ///
    /// - Parameters:
    ///   - name: The canonical grammar name (e.g., "javascript", "python").
    ///   - cacheURL: The application's grammar cache directory.
    /// - Returns: The loaded grammar, or nil if not found or failed to load.
    static func loadGrammarSync(_ name: String, cacheURL: URL) -> LoadedGrammar? {
        // Check Homebrew directories
        for prefix in homebrewPrefixes {
            let homebrewURL = URL(fileURLWithPath: "\(prefix)/share/swiftmarkdown-grammars")
            let grammarDir = homebrewURL.appendingPathComponent(name)
            let dylibURL = grammarDir.appendingPathComponent("\(name).dylib")
            let queriesURL = grammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

            if FileManager.default.fileExists(atPath: dylibURL.path) {
                if let grammar = loadFromDisk(name: name, dylibURL: dylibURL, queriesURL: queriesURL) {
                    return grammar
                }
            }
        }

        // Check cache directory
        let cacheGrammarDir = cacheURL.appendingPathComponent(name)
        let cacheDylibURL = cacheGrammarDir.appendingPathComponent("\(name).dylib")
        let cacheQueriesURL = cacheGrammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

        if FileManager.default.fileExists(atPath: cacheDylibURL.path) {
            return loadFromDisk(name: name, dylibURL: cacheDylibURL, queriesURL: cacheQueriesURL)
        }

        return nil
    }

    /// Loads a grammar from specific dylib and queries paths.
    ///
    /// - Parameters:
    ///   - name: The grammar name (used to find the tree_sitter_<name> symbol).
    ///   - dylibURL: Path to the compiled grammar dylib.
    ///   - queriesURL: Path to the highlights.scm query file.
    /// - Returns: The loaded grammar, or nil if loading failed.
    static func loadFromDisk(name: String, dylibURL: URL, queriesURL: URL) -> LoadedGrammar? {
        guard let handle = dlopen(dylibURL.path, RTLD_NOW) else {
            return nil
        }

        let symbolName = "tree_sitter_\(name)"
        guard let symbol = dlsym(handle, symbolName) else {
            return nil
        }

        typealias LanguageFunc = @convention(c) () -> OpaquePointer
        let languageFunc = unsafeBitCast(symbol, to: LanguageFunc.self)
        let languagePtr = languageFunc()

        let language = Language(language: languagePtr)

        return LoadedGrammar(
            language: language,
            queriesURL: queriesURL,
            name: name
        )
    }
}
