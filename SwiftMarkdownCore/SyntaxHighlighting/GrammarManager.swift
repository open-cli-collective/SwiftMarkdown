import Foundation
import SwiftTreeSitter

/// A loaded grammar ready for use with tree-sitter.
public struct LoadedGrammar: Sendable {
    /// The tree-sitter language pointer.
    public let language: Language

    /// Path to the highlights.scm query file.
    public let queriesURL: URL

    /// The canonical name of the grammar.
    public let name: String
}

/// Manages downloading, caching, and loading tree-sitter grammars.
///
/// Grammars are downloaded from GitHub releases on first use and cached
/// permanently in `~/Library/Application Support/SwiftMarkdown/Grammars/`.
///
/// ## Example
/// ```swift
/// let manager = GrammarManager.shared
/// if let grammar = try await manager.grammar(for: "javascript") {
///     // Use grammar.language with tree-sitter
/// }
/// ```
public actor GrammarManager {
    /// Shared instance for the application.
    public static let shared = GrammarManager()

    // swiftlint:disable force_unwrapping
    /// Base URL for downloading grammars from GitHub releases.
    public static let defaultReleaseBaseURL = URL(
        string: "https://github.com/open-cli-collective/apple-tree-sitter-grammars/releases/latest/download"
    )!
    // swiftlint:enable force_unwrapping

    private let cacheURL: URL
    private let releaseBaseURL: URL
    private let urlSession: URLSession

    private var manifest: GrammarManifest?
    private var loadedGrammars: [String: LoadedGrammar] = [:]
    private var loadingTasks: [String: Task<LoadedGrammar?, Error>] = [:]

    /// Creates a grammar manager with custom configuration.
    ///
    /// - Parameters:
    ///   - cacheURL: Directory for cached grammars. Defaults to Application Support.
    ///   - releaseBaseURL: Base URL for downloading grammars.
    ///   - urlSession: URLSession for network requests.
    public init(
        cacheURL: URL? = nil,
        releaseBaseURL: URL = GrammarManager.defaultReleaseBaseURL,
        urlSession: URLSession = .shared
    ) {
        self.releaseBaseURL = releaseBaseURL
        self.urlSession = urlSession

        if let cacheURL = cacheURL {
            self.cacheURL = cacheURL
        } else {
            // swiftlint:disable:next force_unwrapping
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.cacheURL = appSupport
                .appendingPathComponent("SwiftMarkdown")
                .appendingPathComponent("Grammars")
        }
    }

    // MARK: - Public API

    /// Gets a grammar for the specified language, downloading if necessary.
    ///
    /// - Parameter language: Language identifier (e.g., "javascript", "js", "py").
    /// - Returns: The loaded grammar, or nil if not available.
    /// - Throws: GrammarError if download or loading fails.
    public func grammar(for language: String) async throws -> LoadedGrammar? {
        // Load manifest if needed
        if manifest == nil {
            manifest = try await loadManifest()
        }

        guard let manifest = manifest,
              let canonical = manifest.canonicalName(for: language) else {
            return nil
        }

        // Already loaded?
        if let grammar = loadedGrammars[canonical] {
            return grammar
        }

        // Already loading? Wait for existing task
        if let task = loadingTasks[canonical] {
            return try await task.value
        }

        // Start loading
        let task = Task<LoadedGrammar?, Error> {
            try await loadGrammar(canonical)
        }
        loadingTasks[canonical] = task

        defer { loadingTasks[canonical] = nil }

        let grammar = try await task.value
        if let grammar = grammar {
            loadedGrammars[canonical] = grammar
        }
        return grammar
    }

    /// Checks if a grammar is available (in manifest).
    public func supportsLanguage(_ language: String) async -> Bool {
        if manifest == nil {
            manifest = try? await loadManifest()
        }
        return manifest?.canonicalName(for: language) != nil
    }

    /// Gets the list of all supported languages.
    public func supportedLanguages() async -> [String] {
        if manifest == nil {
            manifest = try? await loadManifest()
        }
        return manifest?.supportedLanguages ?? []
    }

    /// Clears all cached grammars and resets state.
    public func clearCache() throws {
        loadedGrammars.removeAll()
        loadingTasks.removeAll()
        manifest = nil

        if FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.removeItem(at: cacheURL)
        }
    }

    /// Returns the cache directory URL.
    public var cacheDirectory: URL {
        cacheURL
    }

    // MARK: - Private Implementation

    private func loadManifest() async throws -> GrammarManifest {
        // Try cached manifest first
        let cachedManifestURL = cacheURL.appendingPathComponent("manifest.json")
        if let cachedData = try? Data(contentsOf: cachedManifestURL) {
            if let manifest = try? GrammarManifest.parse(from: cachedData) {
                return manifest
            }
        }

        // Download fresh manifest
        let manifestURL = releaseBaseURL.appendingPathComponent("manifest.json")
        let (data, response) = try await urlSession.data(from: manifestURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GrammarError.networkError("Failed to download manifest")
        }

        let manifest = try GrammarManifest.parse(from: data)

        // Cache the manifest
        try ensureCacheDirectory()
        try data.write(to: cachedManifestURL)

        return manifest
    }

    private func loadGrammar(_ name: String) async throws -> LoadedGrammar? {
        let grammarDir = cacheURL.appendingPathComponent(name)
        let dylibURL = grammarDir.appendingPathComponent("\(name).dylib")
        let queriesURL = grammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

        // Check cache
        if FileManager.default.fileExists(atPath: dylibURL.path) {
            return try loadFromCache(name: name, dylibURL: dylibURL, queriesURL: queriesURL)
        }

        // Download
        try await downloadGrammar(name, to: grammarDir)

        return try loadFromCache(name: name, dylibURL: dylibURL, queriesURL: queriesURL)
    }

    private func downloadGrammar(_ name: String, to directory: URL) async throws {
        let tarballURL = releaseBaseURL.appendingPathComponent("\(name).tar.gz")

        let (tempURL, response) = try await urlSession.download(from: tarballURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GrammarError.downloadFailed(name, "HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        try ensureCacheDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Extract tarball using tar command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xzf", tempURL.path, "-C", directory.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw GrammarError.extractionFailed(name, "tar exited with status \(process.terminationStatus)")
        }

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }

    private func loadFromCache(name: String, dylibURL: URL, queriesURL: URL) throws -> LoadedGrammar {
        guard let handle = dlopen(dylibURL.path, RTLD_NOW) else {
            let error = String(cString: dlerror())
            throw GrammarError.loadFailed(name, error)
        }

        // Get tree_sitter_<name> symbol
        let symbolName = "tree_sitter_\(name)"
        guard let symbol = dlsym(handle, symbolName) else {
            throw GrammarError.symbolNotFound(symbolName)
        }

        // Cast to tree-sitter language function and call it
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

    private func ensureCacheDirectory() throws {
        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            do {
                try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
            } catch {
                throw GrammarError.cacheDirectoryError(error.localizedDescription)
            }
        }
    }
}
