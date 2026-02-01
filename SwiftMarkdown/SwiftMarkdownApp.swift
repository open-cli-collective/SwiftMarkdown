import SwiftUI
import SwiftMarkdownCore

@main
struct SwiftMarkdownApp: App {
    @StateObject private var settingsManager = SettingsManager()

    init() {
        // Pre-load common grammars in background to reduce first-render latency
        Task.detached(priority: .utility) {
            await GrammarManager.shared.preloadCommonGrammars()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        Settings {
            LanguagesSettingsView()
        }
    }

    /// Maps the appearance mode setting to a SwiftUI ColorScheme.
    private var colorScheme: ColorScheme? {
        switch settingsManager.settings.appearance {
        case .system:
            return nil  // Follow system
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension Notification.Name {
    static let openDocument = Notification.Name("openDocument")
}
