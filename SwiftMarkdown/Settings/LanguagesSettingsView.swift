import SwiftUI
import SwiftMarkdownCore

/// Settings view for managing syntax highlighting languages.
struct LanguagesSettingsView: View {
    @StateObject private var viewModel = LanguagesViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Syntax Highlighting Languages")
                    .font(.headline)
                Text("Grammars are downloaded on first use and cached permanently.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Grammar list
            if viewModel.isLoading {
                ProgressView("Loading languages...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.grammars) { grammar in
                        GrammarRowView(
                            grammar: grammar,
                            onDownload: {
                                Task {
                                    await viewModel.downloadGrammar(grammar.id)
                                }
                            }
                        )
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Footer with actions
            VStack(alignment: .leading, spacing: 12) {
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button("Download Popular (10)") {
                        Task {
                            await viewModel.downloadPopular()
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Button("Download All") {
                        Task {
                            await viewModel.downloadAll()
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()

                    Button("Clear Cache") {
                        Task {
                            await viewModel.clearCache()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                // Cache info
                HStack {
                    Text("Cache location:")
                        .foregroundColor(.secondary)
                    Text("~/Library/Application Support/SwiftMarkdown/Grammars/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Cache size:")
                        .foregroundColor(.secondary)
                    Text(LanguagesViewModel.formatBytes(viewModel.cacheSize))
                        .font(.caption)
                    Text("(\(viewModel.grammars.filter { $0.isInstalled && !$0.isBundled }.count) languages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .task {
            await viewModel.loadGrammars()
        }
    }
}

/// A row displaying a single grammar.
struct GrammarRowView: View {
    let grammar: LanguagesViewModel.GrammarItem
    let onDownload: () -> Void

    var body: some View {
        HStack {
            // Status indicator
            if grammar.isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }

            // Grammar info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(grammar.displayName)
                        .fontWeight(.medium)
                    if grammar.isBundled {
                        Text("(bundled)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Text("\(grammar.version) • \(grammar.license)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status/action
            if grammar.isDownloading {
                ProgressView()
                    .scaleEffect(0.7)
            } else if grammar.isInstalled {
                Text("Installed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button("Download") {
                    onDownload()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text(LanguagesViewModel.formatBytes(grammar.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LanguagesSettingsView()
}
