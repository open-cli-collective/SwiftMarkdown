import SwiftUI
import SwiftMarkdownCore

@main
struct SwiftMarkdownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
}

extension Notification.Name {
    static let openDocument = Notification.Name("openDocument")
}
