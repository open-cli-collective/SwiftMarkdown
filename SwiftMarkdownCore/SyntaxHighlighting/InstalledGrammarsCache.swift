import Foundation

/// Thread-safe cache for installed grammar information.
/// This is a separate class to allow nonisolated access from GrammarManager actor methods.
final class InstalledGrammarsCache: @unchecked Sendable {
    private let lock = NSLock()
    private var installedGrammars: Set<String>?
    private var grammarSources: [String: GrammarSource] = [:]

    /// Returns cached installed grammars, or nil if cache is empty.
    func getCachedGrammars() -> Set<String>? {
        lock.lock()
        defer { lock.unlock() }
        return installedGrammars
    }

    /// Stores installed grammars in cache.
    func setCachedGrammars(_ grammars: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        installedGrammars = grammars
    }

    /// Returns cached grammar source, or nil if not cached.
    func getCachedSource(for name: String) -> GrammarSource? {
        lock.lock()
        defer { lock.unlock() }
        return grammarSources[name]
    }

    /// Stores grammar source in cache.
    func setCachedSource(_ source: GrammarSource, for name: String) {
        lock.lock()
        defer { lock.unlock() }
        grammarSources[name] = source
    }

    /// Clears all cached data.
    func invalidate() {
        lock.lock()
        defer { lock.unlock() }
        installedGrammars = nil
        grammarSources.removeAll()
    }
}
