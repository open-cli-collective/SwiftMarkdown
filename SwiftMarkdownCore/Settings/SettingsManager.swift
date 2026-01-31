import Foundation
import Combine

/// Manages application settings, loading from and saving to ~/.config/swiftmarkdown/settings.json.
///
/// The manager is designed to be resilient:
/// - Returns default settings if the file doesn't exist
/// - Returns default settings if the JSON is invalid
/// - Creates the settings directory if it doesn't exist when saving
/// - Handles missing keys by using defaults (forward compatibility)
/// - Ignores unknown keys (backward compatibility)
public final class SettingsManager: ObservableObject {
    /// The current settings.
    @Published public private(set) var settings: Settings

    private let fileSystem: FileSystemProtocol
    private let settingsURL: URL
    private let directoryURL: URL

    /// Creates a new settings manager.
    /// - Parameters:
    ///   - fileSystem: The filesystem to use (defaults to real filesystem).
    ///   - baseDirectory: The base directory for settings (defaults to ~/.config/swiftmarkdown).
    public init(
        fileSystem: FileSystemProtocol = RealFileSystem(),
        baseDirectory: URL? = nil
    ) {
        self.fileSystem = fileSystem

        let directory = baseDirectory ?? Self.defaultBaseDirectory
        self.directoryURL = directory
        self.settingsURL = directory.appendingPathComponent("settings.json")

        // Load settings synchronously during init
        self.settings = Self.loadSettings(from: settingsURL, using: fileSystem)
    }

    /// The default base directory: ~/.config/swiftmarkdown
    public static var defaultBaseDirectory: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("swiftmarkdown", isDirectory: true)
    }

    /// Reloads settings from disk.
    public func reload() {
        settings = Self.loadSettings(from: settingsURL, using: fileSystem)
    }

    /// Saves the current settings to disk.
    /// - Throws: An error if the settings cannot be saved.
    public func save() throws {
        try save(settings)
    }

    /// Saves the given settings to disk and updates the current settings.
    /// - Parameter newSettings: The settings to save.
    /// - Throws: An error if the settings cannot be saved.
    public func save(_ newSettings: Settings) throws {
        // Ensure directory exists
        if !fileSystem.fileExists(at: directoryURL) {
            try fileSystem.createDirectory(at: directoryURL)
        }

        // Encode settings
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newSettings)

        // Write atomically
        try fileSystem.write(data, to: settingsURL)

        // Update published settings
        settings = newSettings
    }

    /// Updates the appearance mode and saves.
    /// - Parameter mode: The new appearance mode.
    /// - Throws: An error if the settings cannot be saved.
    public func setAppearance(_ mode: AppearanceMode) throws {
        var newSettings = settings
        newSettings.appearance = mode
        try save(newSettings)
    }

    // MARK: - Private

    private static func loadSettings(from url: URL, using fileSystem: FileSystemProtocol) -> Settings {
        do {
            let data = try fileSystem.read(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Settings.self, from: data)
        } catch {
            // Return defaults on any error (file not found, invalid JSON, etc.)
            return Settings.default
        }
    }
}
