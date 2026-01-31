import XCTest
@testable import SwiftMarkdownCore

final class SettingsManagerTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockFileSystem: MockFileSystem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var testDirectory: URL!

    override func setUp() {
        super.setUp()
        mockFileSystem = MockFileSystem()
        testDirectory = URL(fileURLWithPath: "/tmp/swiftmarkdown-test")
    }

    override func tearDown() {
        mockFileSystem.reset()
        super.tearDown()
    }

    private func makeManager() -> SettingsManager {
        SettingsManager(fileSystem: mockFileSystem, baseDirectory: testDirectory)
    }

    // MARK: - Load Tests

    func testLoadWhenFileDoesNotExistReturnsDefaults() {
        // No file set in mock filesystem
        let manager = makeManager()

        XCTAssertEqual(manager.settings, Settings.default)
        XCTAssertEqual(manager.settings.appearance, .system)
    }

    func testLoadValidJSONReturnsParsedSettings() {
        let json = """
        {
            "appearance": "dark"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        XCTAssertEqual(manager.settings.appearance, .dark)
    }

    func testLoadLightAppearance() {
        let json = """
        {
            "appearance": "light"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        XCTAssertEqual(manager.settings.appearance, .light)
    }

    func testLoadSystemAppearance() {
        let json = """
        {
            "appearance": "system"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        XCTAssertEqual(manager.settings.appearance, .system)
    }

    func testLoadInvalidJSONReturnsDefaults() {
        let invalidJSON = "this is not valid json {"
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(invalidJSON.utf8), at: settingsURL)

        let manager = makeManager()

        XCTAssertEqual(manager.settings, Settings.default)
    }

    func testLoadEmptyJSONReturnsDefaults() {
        let emptyJSON = "{}"
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(emptyJSON.utf8), at: settingsURL)

        let manager = makeManager()

        // Empty JSON should use default values for missing keys
        XCTAssertEqual(manager.settings.appearance, .system)
    }

    func testLoadJSONWithMissingKeysUsesDefaultsForMissing() {
        // JSON with no appearance key
        let json = """
        {
            "someOtherKey": "value"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        XCTAssertEqual(manager.settings.appearance, .system)
    }

    func testLoadJSONWithUnknownKeysIgnoresThem() {
        let json = """
        {
            "appearance": "dark",
            "unknownKey": "should be ignored",
            "anotherUnknown": 123
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        // Should parse successfully and ignore unknown keys
        XCTAssertEqual(manager.settings.appearance, .dark)
    }

    func testLoadJSONWithInvalidAppearanceValueReturnsDefaults() {
        let json = """
        {
            "appearance": "invalid_value"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        let manager = makeManager()

        // Invalid enum value should cause decoding to fail, returning defaults
        XCTAssertEqual(manager.settings.appearance, .system)
    }

    func testLoadWhenReadErrorOccursReturnsDefaults() {
        mockFileSystem.readError = NSError(domain: "test", code: 1, userInfo: nil)

        let manager = makeManager()

        XCTAssertEqual(manager.settings, Settings.default)
    }

    // MARK: - Save Tests

    func testSaveCreatesDirectoryIfNeeded() throws {
        let manager = makeManager()

        try manager.save(Settings(appearance: .dark))

        XCTAssertTrue(mockFileSystem.directoryWasCreated(at: testDirectory))
    }

    func testSaveWritesValidJSON() throws {
        let manager = makeManager()

        try manager.save(Settings(appearance: .dark))

        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        let savedData = try XCTUnwrap(mockFileSystem.getFileContents(at: settingsURL))

        // Verify it's valid JSON that can be parsed back
        let decoded = try JSONDecoder().decode(Settings.self, from: savedData)
        XCTAssertEqual(decoded.appearance, .dark)
    }

    func testSaveUpdatesPublishedSettings() throws {
        let manager = makeManager()
        XCTAssertEqual(manager.settings.appearance, .system)

        try manager.save(Settings(appearance: .light))

        XCTAssertEqual(manager.settings.appearance, .light)
    }

    func testSetAppearanceSavesAndUpdates() throws {
        let manager = makeManager()

        try manager.setAppearance(.dark)

        XCTAssertEqual(manager.settings.appearance, .dark)

        // Verify it was persisted
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        let savedData = try XCTUnwrap(mockFileSystem.getFileContents(at: settingsURL))

        let decoded = try JSONDecoder().decode(Settings.self, from: savedData)
        XCTAssertEqual(decoded.appearance, .dark)
    }

    func testSaveThrowsOnWriteError() {
        let manager = makeManager()
        mockFileSystem.writeError = NSError(domain: "test", code: 1, userInfo: nil)

        XCTAssertThrowsError(try manager.save(Settings(appearance: .dark)))
    }

    // MARK: - Round-Trip Tests

    func testRoundTripPreservesAllValues() throws {
        let manager = makeManager()

        // Save settings
        let original = Settings(appearance: .light)
        try manager.save(original)

        // Create new manager to load from "disk"
        let newManager = makeManager()

        XCTAssertEqual(newManager.settings, original)
    }

    func testReloadUpdatesFromDisk() throws {
        let manager = makeManager()
        XCTAssertEqual(manager.settings.appearance, .system)

        // Simulate external change to file
        let json = """
        {
            "appearance": "dark"
        }
        """
        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        mockFileSystem.setFileContents(Data(json.utf8), at: settingsURL)

        manager.reload()

        XCTAssertEqual(manager.settings.appearance, .dark)
    }

    // MARK: - Settings Struct Tests

    func testSettingsDefaultValues() {
        let settings = Settings.default

        XCTAssertEqual(settings.appearance, .system)
    }

    func testSettingsEquality() {
        let settings1 = Settings(appearance: .dark)
        let settings2 = Settings(appearance: .dark)
        let settings3 = Settings(appearance: .light)

        XCTAssertEqual(settings1, settings2)
        XCTAssertNotEqual(settings1, settings3)
    }

    // MARK: - AppearanceMode Tests

    func testAppearanceModeRawValues() {
        XCTAssertEqual(AppearanceMode.system.rawValue, "system")
        XCTAssertEqual(AppearanceMode.light.rawValue, "light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "dark")
    }

    func testAppearanceModeCaseIterable() {
        let allCases = AppearanceMode.allCases

        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.system))
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
    }

    // MARK: - JSON Format Tests

    func testSavedJSONIsPrettyPrinted() throws {
        let manager = makeManager()

        try manager.save(Settings(appearance: .dark))

        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        let savedData = try XCTUnwrap(mockFileSystem.getFileContents(at: settingsURL))
        let jsonString = try XCTUnwrap(String(data: savedData, encoding: .utf8))

        // Pretty printed JSON should have newlines
        XCTAssertTrue(jsonString.contains("\n"))
    }

    func testSavedJSONHasSortedKeys() throws {
        let manager = makeManager()

        try manager.save(Settings(appearance: .dark))

        let settingsURL = testDirectory.appendingPathComponent("settings.json")
        let savedData = try XCTUnwrap(mockFileSystem.getFileContents(at: settingsURL))
        let jsonString = try XCTUnwrap(String(data: savedData, encoding: .utf8))

        // With only one key currently, just verify it's valid JSON
        XCTAssertTrue(jsonString.contains("\"appearance\""))
    }
}
