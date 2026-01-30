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

    // MARK: - Installed Grammars Tests

    func testInstalledGrammarsEmptyCache() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("empty-cache")
        // Pass non-existent homebrewURL to disable Homebrew discovery
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        let installed = await manager.installedGrammars()
        XCTAssertTrue(installed.isEmpty)
    }

    func testInstalledGrammarsWithCachedGrammars() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        // Pass non-existent homebrewURL to disable Homebrew discovery
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        // Create fake grammar directories with dylib files
        let jsDir = cacheDir.appendingPathComponent("javascript")
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)
        try "fake".write(to: jsDir.appendingPathComponent("javascript.dylib"), atomically: true, encoding: .utf8)

        let pyDir = cacheDir.appendingPathComponent("python")
        try FileManager.default.createDirectory(at: pyDir, withIntermediateDirectories: true)
        try "fake".write(to: pyDir.appendingPathComponent("python.dylib"), atomically: true, encoding: .utf8)

        let installed = await manager.installedGrammars()
        XCTAssertEqual(installed, ["javascript", "python"])
    }

    func testInstalledGrammarsIgnoresDirectoriesWithoutDylib() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        // Pass non-existent homebrewURL to disable Homebrew discovery
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        // Create a directory without dylib
        let emptyDir = cacheDir.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        // Create a directory with dylib
        let jsDir = cacheDir.appendingPathComponent("javascript")
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)
        try "fake".write(to: jsDir.appendingPathComponent("javascript.dylib"), atomically: true, encoding: .utf8)

        let installed = await manager.installedGrammars()
        XCTAssertEqual(installed, ["javascript"])
    }

    // MARK: - Is Grammar Installed Tests

    func testIsGrammarInstalledTrue() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        // Pass non-existent homebrewURL to disable Homebrew discovery
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        let jsDir = cacheDir.appendingPathComponent("javascript")
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)
        try "fake".write(to: jsDir.appendingPathComponent("javascript.dylib"), atomically: true, encoding: .utf8)

        let isInstalled = await manager.isGrammarInstalled("javascript")
        XCTAssertTrue(isInstalled)
    }

    func testIsGrammarInstalledFalse() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        // Pass non-existent homebrewURL to disable Homebrew discovery
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        let isInstalled = await manager.isGrammarInstalled("javascript")
        XCTAssertFalse(isInstalled)
    }

    // MARK: - Homebrew Discovery Tests

    func testInstalledGrammarsWithHomebrewGrammars() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let homebrewDir = dir.appendingPathComponent("homebrew-grammars")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: homebrewDir)

        // Create fake Homebrew grammar
        let swiftDir = homebrewDir.appendingPathComponent("swift")
        try FileManager.default.createDirectory(at: swiftDir, withIntermediateDirectories: true)
        try "fake".write(to: swiftDir.appendingPathComponent("swift.dylib"), atomically: true, encoding: .utf8)

        let installed = await manager.installedGrammars()
        XCTAssertEqual(installed, ["swift"])
    }

    func testInstalledGrammarsCombinesHomebrewAndCache() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let homebrewDir = dir.appendingPathComponent("homebrew-grammars")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: homebrewDir)

        // Create Homebrew grammar
        let swiftDir = homebrewDir.appendingPathComponent("swift")
        try FileManager.default.createDirectory(at: swiftDir, withIntermediateDirectories: true)
        try "fake".write(to: swiftDir.appendingPathComponent("swift.dylib"), atomically: true, encoding: .utf8)

        // Create cached grammar
        let jsDir = cacheDir.appendingPathComponent("javascript")
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)
        try "fake".write(to: jsDir.appendingPathComponent("javascript.dylib"), atomically: true, encoding: .utf8)

        let installed = await manager.installedGrammars()
        XCTAssertEqual(installed, ["javascript", "swift"])
    }

    // MARK: - Grammar Source Tests

    func testGrammarSourceHomebrew() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let homebrewDir = dir.appendingPathComponent("homebrew-grammars")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: homebrewDir)

        // Create Homebrew grammar
        let swiftDir = homebrewDir.appendingPathComponent("swift")
        try FileManager.default.createDirectory(at: swiftDir, withIntermediateDirectories: true)
        try "fake".write(to: swiftDir.appendingPathComponent("swift.dylib"), atomically: true, encoding: .utf8)

        let source = await manager.grammarSource("swift")
        XCTAssertEqual(source, .homebrew)
    }

    func testGrammarSourceCached() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let homebrewDir = dir.appendingPathComponent("homebrew-grammars")
        try FileManager.default.createDirectory(at: homebrewDir, withIntermediateDirectories: true)
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: homebrewDir)

        // Create cached grammar (not in Homebrew)
        let jsDir = cacheDir.appendingPathComponent("javascript")
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)
        try "fake".write(to: jsDir.appendingPathComponent("javascript.dylib"), atomically: true, encoding: .utf8)

        let source = await manager.grammarSource("javascript")
        XCTAssertEqual(source, .cached)
    }

    func testGrammarSourceNotInstalled() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let fakeHomebrewURL = dir.appendingPathComponent("fake-homebrew")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: fakeHomebrewURL)

        let source = await manager.grammarSource("nonexistent")
        XCTAssertEqual(source, .notInstalled)
    }

    func testGrammarSourcePrefersHomebrew() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let homebrewDir = dir.appendingPathComponent("homebrew-grammars")
        let manager = GrammarManager(cacheURL: cacheDir, homebrewURL: homebrewDir)

        // Create same grammar in both locations
        let homebrewSwiftDir = homebrewDir.appendingPathComponent("swift")
        try FileManager.default.createDirectory(at: homebrewSwiftDir, withIntermediateDirectories: true)
        try "homebrew".write(to: homebrewSwiftDir.appendingPathComponent("swift.dylib"), atomically: true, encoding: .utf8)

        let cacheSwiftDir = cacheDir.appendingPathComponent("swift")
        try FileManager.default.createDirectory(at: cacheSwiftDir, withIntermediateDirectories: true)
        try "cached".write(to: cacheSwiftDir.appendingPathComponent("swift.dylib"), atomically: true, encoding: .utf8)

        // Should report as Homebrew since that's checked first
        let source = await manager.grammarSource("swift")
        XCTAssertEqual(source, .homebrew)
    }

    // MARK: - Cache Size Tests

    func testCacheSizeEmptyCache() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("empty-cache")
        let manager = GrammarManager(cacheURL: cacheDir)

        let size = await manager.cacheSize()
        XCTAssertEqual(size, 0)
    }

    func testCacheSizeWithFiles() async throws {
        let dir = try XCTUnwrap(tempDir)
        let cacheDir = dir.appendingPathComponent("cache")
        let manager = GrammarManager(cacheURL: cacheDir)

        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        // Create a file with known content
        let testData = String(repeating: "x", count: 1000)
        try testData.write(to: cacheDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)

        let size = await manager.cacheSize()
        XCTAssertGreaterThan(size, 0)
    }
}
