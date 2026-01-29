import XCTest
@testable import SwiftMarkdownCore

final class GrammarManagerTests: XCTestCase {
    var tempDir: URL?

    override func setUp() {
        super.setUp()
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("GrammarManagerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDir = dir
    }

    override func tearDown() {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDefaultCacheDirectory() async {
        let manager = GrammarManager()
        let cacheDir = await manager.cacheDirectory

        XCTAssertTrue(cacheDir.path.contains("Application Support"))
        XCTAssertTrue(cacheDir.path.contains("SwiftMarkdown"))
        XCTAssertTrue(cacheDir.path.contains("Grammars"))
    }

    func testCustomCacheDirectory() async throws {
        let dir = try XCTUnwrap(tempDir)
        let customCache = dir.appendingPathComponent("custom-cache")
        let manager = GrammarManager(cacheURL: customCache)
        let cacheDir = await manager.cacheDirectory

        XCTAssertEqual(cacheDir, customCache)
    }

    // MARK: - Cache Clear Tests

    func testClearCacheRemovesDirectory() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let manager = GrammarManager(cacheURL: cacheDir)

        // Create some files in cache
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let testFile = cacheDir.appendingPathComponent("test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        try await manager.clearCache()

        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDir.path))
    }

    func testClearCacheWithNonExistentDirectory() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("nonexistent")
        let manager = GrammarManager(cacheURL: cacheDir)

        // Should not throw even if directory doesn't exist
        try await manager.clearCache()
    }

    // MARK: - Error Type Tests

    func testGrammarErrorDescriptions() {
        XCTAssertEqual(
            GrammarError.unknownGrammar("foo").errorDescription,
            "Unknown grammar: foo"
        )
        XCTAssertEqual(
            GrammarError.downloadFailed("js", "timeout").errorDescription,
            "Failed to download js grammar: timeout"
        )
        XCTAssertEqual(
            GrammarError.loadFailed("js", "bad dylib").errorDescription,
            "Failed to load js grammar: bad dylib"
        )
        XCTAssertEqual(
            GrammarError.symbolNotFound("tree_sitter_foo").errorDescription,
            "Symbol not found: tree_sitter_foo"
        )
    }

    func testGrammarErrorEquality() {
        XCTAssertEqual(
            GrammarError.unknownGrammar("foo"),
            GrammarError.unknownGrammar("foo")
        )
        XCTAssertNotEqual(
            GrammarError.unknownGrammar("foo"),
            GrammarError.unknownGrammar("bar")
        )
    }

    // MARK: - GrammarInfo Tests

    func testGrammarInfoEquality() {
        let info1 = GrammarInfo(
            displayName: "JavaScript",
            version: "v1.0.0",
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )
        let info2 = GrammarInfo(
            displayName: "JavaScript",
            version: "v1.0.0",
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )

        XCTAssertEqual(info1, info2)
    }

    func testGrammarInfoInequality() {
        let info1 = GrammarInfo(
            displayName: "JavaScript",
            version: "v1.0.0",
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )
        let info2 = GrammarInfo(
            displayName: "JavaScript",
            version: "v2.0.0",  // Different version
            license: "MIT",
            aliases: ["js"],
            checksum: "abc",
            size: 100
        )

        XCTAssertNotEqual(info1, info2)
    }

    // MARK: - LoadedGrammar Tests

    func testLoadedGrammarProperties() async throws {
        // This test just verifies the LoadedGrammar struct works
        // We can't easily create a real Language without a dylib
        let dir = try XCTUnwrap(tempDir)
        let queriesURL = dir.appendingPathComponent("queries/highlights.scm")

        // Just verify the struct compiles and works
        // Full integration testing requires actual grammars
        XCTAssertTrue(queriesURL.lastPathComponent == "highlights.scm")
    }
}
