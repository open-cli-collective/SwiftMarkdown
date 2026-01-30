import Foundation
import SwiftTreeSitter

/// Indicates where a grammar was loaded from.
public enum GrammarSource: Equatable, Sendable {
    /// Installed via Homebrew formula.
    case homebrew
    /// Downloaded and cached by the app.
    case cached
    /// Not installed locally.
    case notInstalled
}

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
/// ## Error Handling
///
/// This class follows a consistent error handling strategy:
///
/// - **Query methods** (`supportsLanguage`, `supportedLanguages`, `getManifest`,
///   `installedGrammars`, `isGrammarInstalled`, `cacheSize`) return optional values
///   or empty collections on failure. They never throw, making them safe for UI code.
///
/// - **Action methods** (`grammar(for:)`, `downloadGrammarOnly`, `clearCache`)
///   throw errors that callers should handle. These are used when the caller needs
///   to know about and respond to failures.
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
    private let overrideHomebrewURL: URL?

    /// Returns the Homebrew grammars directory if it exists.
    /// Checks both Apple Silicon (/opt/homebrew) and Intel (/usr/local) prefixes.
    /// If an override URL was provided in the initializer, uses that instead.
    private var homebrewGrammarsURL: URL? {
        // If override is set, use it (allows tests to disable Homebrew discovery)
        if let override = overrideHomebrewURL {
            return FileManager.default.fileExists(atPath: override.path) ? override : nil
        }

        let prefixes = ["/opt/homebrew", "/usr/local"]
        for prefix in prefixes {
            let url = URL(fileURLWithPath: "\(prefix)/share/swiftmarkdown-grammars")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private var manifest: GrammarManifest?
    private var loadedGrammars: [String: LoadedGrammar] = [:]
    private var loadingTasks: [String: Task<LoadedGrammar?, Error>] = [:]

    /// Creates a grammar manager with custom configuration.
    ///
    /// - Parameters:
    ///   - cacheURL: Directory for cached grammars. Defaults to Application Support.
    ///   - releaseBaseURL: Base URL for downloading grammars.
    ///   - urlSession: URLSession for network requests.
    ///   - homebrewURL: Override for Homebrew grammars directory. Pass a non-existent path to disable
    ///                  Homebrew discovery (useful for testing). Defaults to nil (auto-detect).
    public init(
        cacheURL: URL? = nil,
        releaseBaseURL: URL = GrammarManager.defaultReleaseBaseURL,
        urlSession: URLSession = .shared,
        homebrewURL: URL? = nil
    ) {
        self.releaseBaseURL = releaseBaseURL
        self.urlSession = urlSession
        self.overrideHomebrewURL = homebrewURL

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
        try await ensureManifestOrThrow()

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
    ///
    /// This is a query method that never throws. Returns `false` if the manifest
    /// cannot be loaded (e.g., no network and no cache).
    public func supportsLanguage(_ language: String) async -> Bool {
        await ensureManifest()
        return manifest?.canonicalName(for: language) != nil
    }

    /// Gets the list of all supported languages.
    ///
    /// This is a query method that never throws. Returns an empty array if the manifest
    /// cannot be loaded.
    public func supportedLanguages() async -> [String] {
        await ensureManifest()
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

    // MARK: - UI Support API

    /// Returns the cached manifest, loading it if necessary.
    ///
    /// This is a query method that never throws. Returns `nil` if the manifest
    /// cannot be loaded.
    public func getManifest() async -> GrammarManifest? {
        await ensureManifest()
        return manifest
    }

    /// Returns the list of installed grammar names from all sources (Homebrew + cache).
    public func installedGrammars() -> [String] {
        var grammars = Set<String>()

        // Check Homebrew directory
        if let homebrewURL = homebrewGrammarsURL {
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: homebrewURL.path)) ?? []
            for name in contents {
                let dylibPath = homebrewURL.appendingPathComponent(name).appendingPathComponent("\(name).dylib").path
                if FileManager.default.fileExists(atPath: dylibPath) {
                    grammars.insert(name)
                }
            }
        }

        // Check cache directory
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: cacheURL.path)) ?? []
            for name in contents {
                let dylibPath = cacheURL.appendingPathComponent(name).appendingPathComponent("\(name).dylib").path
                if FileManager.default.fileExists(atPath: dylibPath) {
                    grammars.insert(name)
                }
            }
        }

        return grammars.sorted()
    }

    /// Checks if a specific grammar is installed (in Homebrew or cache).
    public func isGrammarInstalled(_ name: String) -> Bool {
        grammarSource(name) != .notInstalled
    }

    /// Returns the source of a grammar (Homebrew, cached, or not installed).
    public func grammarSource(_ name: String) -> GrammarSource {
        // Check Homebrew first
        if let homebrewURL = homebrewGrammarsURL {
            let dylibPath = homebrewURL.appendingPathComponent(name).appendingPathComponent("\(name).dylib").path
            if FileManager.default.fileExists(atPath: dylibPath) {
                return .homebrew
            }
        }

        // Check cache
        let cachedDylibPath = cacheURL.appendingPathComponent(name).appendingPathComponent("\(name).dylib").path
        if FileManager.default.fileExists(atPath: cachedDylibPath) {
            return .cached
        }

        return .notInstalled
    }

    /// Returns the total cache size in bytes.
    public func cacheSize() -> Int64 {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return 0
        }

        var totalSize: Int64 = 0
        let enumerator = FileManager.default.enumerator(atPath: cacheURL.path)

        while let file = enumerator?.nextObject() as? String {
            let filePath = cacheURL.appendingPathComponent(file).path
            if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }

    /// Downloads a grammar without loading it into memory.
    ///
    /// Use this to pre-download grammars for offline use.
    /// - Parameter language: The language to download.
    /// - Throws: GrammarError if download fails.
    public func downloadGrammarOnly(_ language: String) async throws {
        try await ensureManifestOrThrow()

        guard let manifest = manifest,
              let canonical = manifest.canonicalName(for: language) else {
            throw GrammarError.unknownGrammar(language)
        }

        // Skip if already cached
        if isGrammarInstalled(canonical) {
            return
        }

        let grammarDir = cacheURL.appendingPathComponent(canonical)
        try await downloadGrammar(canonical, to: grammarDir)
    }

    // MARK: - Private Implementation

    /// Ensures the manifest is loaded, loading it if necessary.
    private func ensureManifest() async {
        if manifest == nil {
            manifest = try? await loadManifest()
        }
    }

    /// Ensures the manifest is loaded, throwing on failure.
    private func ensureManifestOrThrow() async throws {
        if manifest == nil {
            manifest = try await loadManifest()
        }
    }

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
        // Check Homebrew directory first
        if let homebrewURL = homebrewGrammarsURL {
            let homebrewGrammarDir = homebrewURL.appendingPathComponent(name)
            let homebrewDylibURL = homebrewGrammarDir.appendingPathComponent("\(name).dylib")
            let homebrewQueriesURL = homebrewGrammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

            if FileManager.default.fileExists(atPath: homebrewDylibURL.path) {
                return try loadFromDisk(name: name, dylibURL: homebrewDylibURL, queriesURL: homebrewQueriesURL)
            }
        }

        // Check cache directory
        let cacheGrammarDir = cacheURL.appendingPathComponent(name)
        let cacheDylibURL = cacheGrammarDir.appendingPathComponent("\(name).dylib")
        let cacheQueriesURL = cacheGrammarDir.appendingPathComponent("queries").appendingPathComponent("highlights.scm")

        if FileManager.default.fileExists(atPath: cacheDylibURL.path) {
            return try loadFromDisk(name: name, dylibURL: cacheDylibURL, queriesURL: cacheQueriesURL)
        }

        // Download to cache
        try await downloadGrammar(name, to: cacheGrammarDir)

        return try loadFromDisk(name: name, dylibURL: cacheDylibURL, queriesURL: cacheQueriesURL)
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

    private func loadFromDisk(name: String, dylibURL: URL, queriesURL: URL) throws -> LoadedGrammar {
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
