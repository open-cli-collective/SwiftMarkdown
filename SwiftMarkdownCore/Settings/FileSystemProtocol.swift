import Foundation

/// Protocol for filesystem operations, enabling dependency injection for testing.
public protocol FileSystemProtocol: Sendable {
    /// Reads data from the specified URL.
    /// - Parameter url: The file URL to read from.
    /// - Returns: The file data, or nil if the file doesn't exist or can't be read.
    func read(from url: URL) throws -> Data

    /// Writes data to the specified URL atomically.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - url: The file URL to write to.
    func write(_ data: Data, to url: URL) throws

    /// Creates a directory at the specified URL, including intermediate directories.
    /// - Parameter url: The directory URL to create.
    func createDirectory(at url: URL) throws

    /// Checks if a file exists at the specified URL.
    /// - Parameter url: The file URL to check.
    /// - Returns: True if the file exists, false otherwise.
    func fileExists(at url: URL) -> Bool
}

/// Default filesystem implementation using FileManager.
public struct RealFileSystem: FileSystemProtocol {
    public init() {}

    public func read(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

/// Mock filesystem for testing.
public final class MockFileSystem: FileSystemProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var files: [URL: Data] = [:]
    private var directories: Set<URL> = []

    /// Error to throw on next read operation (for testing error handling).
    public var readError: Error?
    /// Error to throw on next write operation (for testing error handling).
    public var writeError: Error?

    public init() {}

    public func read(from url: URL) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        if let error = readError {
            throw error
        }

        guard let data = files[url] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return data
    }

    public func write(_ data: Data, to url: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        if let error = writeError {
            throw error
        }

        files[url] = data
    }

    public func createDirectory(at url: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        directories.insert(url)
    }

    public func fileExists(at url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return files[url] != nil
    }

    // MARK: - Test Helpers

    /// Sets file contents for testing.
    public func setFileContents(_ data: Data, at url: URL) {
        lock.lock()
        defer { lock.unlock() }

        files[url] = data
    }

    /// Gets file contents for verification.
    public func getFileContents(at url: URL) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        return files[url]
    }

    /// Checks if a directory was created.
    public func directoryWasCreated(at url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return directories.contains(url)
    }

    /// Resets all state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        files.removeAll()
        directories.removeAll()
        readError = nil
        writeError = nil
    }
}
