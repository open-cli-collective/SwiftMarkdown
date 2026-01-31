import Foundation

/// Application appearance mode.
public enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    /// Follow the system appearance (light or dark based on macOS settings).
    case system
    /// Always use light appearance.
    case light
    /// Always use dark appearance.
    case dark
}

/// Application settings stored in ~/.config/swiftmarkdown/settings.json.
///
/// This struct is designed to be extensible - new settings can be added as optional
/// properties with default values, maintaining backward compatibility with existing
/// settings files.
public struct Settings: Codable, Equatable, Sendable {
    /// The appearance mode for the application.
    public var appearance: AppearanceMode

    /// Default settings used when no settings file exists or on parse errors.
    public static let `default` = Settings(appearance: .system)

    public init(appearance: AppearanceMode = .system) {
        self.appearance = appearance
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case appearance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Use default values for missing keys (forward compatibility)
        self.appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance)
            ?? Settings.default.appearance
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appearance, forKey: .appearance)
    }
}
