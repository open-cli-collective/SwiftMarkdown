import Foundation
import SwiftMarkdownCore

/// View model for managing grammar downloads and display.
@MainActor
final class LanguagesViewModel: ObservableObject {
    @Published var grammars: [GrammarItem] = []
    @Published var isLoading = false
    @Published var cacheSize: Int64 = 0
    @Published var errorMessage: String?

    private let grammarManager: GrammarManager

    /// Represents a grammar for display in the UI.
    struct GrammarItem: Identifiable {
        let id: String  // canonical name
        let displayName: String
        let version: String
        let license: String
        let size: Int
        var source: GrammarSource
        var isDownloading: Bool = false

        /// Whether the grammar is installed (from any source).
        var isInstalled: Bool { source != .notInstalled }
    }

    init(grammarManager: GrammarManager = .shared) {
        self.grammarManager = grammarManager
    }

    /// Loads the grammar list from the manifest.
    func loadGrammars() async {
        isLoading = true
        errorMessage = nil

        var items: [GrammarItem] = []

        // Get manifest and build grammar list with sources
        if let manifest = await grammarManager.getManifest() {
            for (name, info) in manifest.grammars.sorted(by: { $0.key < $1.key }) {
                let source = grammarManager.grammarSource(name)
                items.append(GrammarItem(
                    id: name,
                    displayName: info.displayName,
                    version: info.version,
                    license: info.license,
                    size: info.size,
                    source: source
                ))
            }
        }

        grammars = items
        cacheSize = grammarManager.cacheSize()
        isLoading = false
    }

    /// Downloads a specific grammar.
    func downloadGrammar(_ id: String) async {
        guard let index = grammars.firstIndex(where: { $0.id == id }) else { return }

        grammars[index].isDownloading = true
        errorMessage = nil

        do {
            try await grammarManager.downloadGrammarOnly(id)
            grammars[index].source = .cached
        } catch {
            errorMessage = "Failed to download \(grammars[index].displayName): \(error.localizedDescription)"
        }

        grammars[index].isDownloading = false
        cacheSize = grammarManager.cacheSize()
    }

    /// Downloads all grammars that aren't installed.
    func downloadAll() async {
        let toDownload = grammars.filter { $0.source == .notInstalled }

        for grammar in toDownload {
            await downloadGrammar(grammar.id)
        }
    }

    /// Downloads the most popular grammars.
    func downloadPopular() async {
        let popular = ["javascript", "python", "typescript", "html", "css", "json", "yaml", "bash", "go", "rust"]

        for name in popular {
            if let grammar = grammars.first(where: { $0.id == name }), !grammar.isInstalled {
                await downloadGrammar(name)
            }
        }
    }

    /// Clears the grammar cache.
    func clearCache() async {
        do {
            try await grammarManager.clearCache()
            await loadGrammars()
        } catch {
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
    }

    /// Formats a byte count for display.
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats a byte count for display (Int version).
    static func formatBytes(_ bytes: Int) -> String {
        formatBytes(Int64(bytes))
    }
}
