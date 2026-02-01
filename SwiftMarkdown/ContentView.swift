import AppKit
import SwiftMarkdownCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = DocumentViewModel()
    @State private var isDropTargeted = false
    @State private var isFilePickerPresented = false

    /// Content types for the file picker.
    private static let markdownContentTypes: [UTType] = {
        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") {
            types.append(md)
        }
        if let markdown = UTType(filenameExtension: "markdown") {
            types.append(markdown)
        }
        // Fallback to plain text if no specific types available
        if types.isEmpty {
            types.append(.plainText)
        }
        return types
    }()

    var body: some View {
        ZStack {
            if viewModel.renderedContent.length == 0 {
                dropZoneView
            } else {
                documentView
            }

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .navigationTitle(viewModel.fileName)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: Self.markdownContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDocument)) { _ in
            isFilePickerPresented = true
        }
    }

    // MARK: - Views

    private var dropZoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(isDropTargeted ? .accentColor : .secondary)

            Text("Drop a Markdown File")
                .font(.title2)
                .fontWeight(.medium)

            Text("Drag and drop a .md or .markdown file here to preview")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("SwiftMarkdown \(SwiftMarkdownCore.version)")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 20)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(20)
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }

    private var documentView: some View {
        NativeMarkdownView(
            attributedString: viewModel.renderedContent,
            onLinkClick: { url in
                NSWorkspace.shared.open(url)
            },
            onFileDrop: { url in
                handleDroppedFile(url)
            }
        )
    }

    private var dropIndicator: some View {
        HStack {
            Image(systemName: "arrow.down.doc")
            Text("Drop to open")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding()
    }

    private var loadingOverlay: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Rendering...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - File Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Validate file type
            guard DocumentViewModel.isMarkdownFile(url) else {
                viewModel.errorMessage = "Only markdown files (.md, .markdown) are supported"
                return
            }

            Task {
                await viewModel.loadFile(at: url)
            }

        case .failure(let error):
            viewModel.errorMessage = "Failed to open file: \(error.localizedDescription)"
        }
    }

    // MARK: - Drop Handling

    private func handleDroppedFile(_ url: URL) {
        guard DocumentViewModel.isMarkdownFile(url) else {
            viewModel.errorMessage = "Only markdown files (.md, .markdown) are supported"
            return
        }

        Task {
            await viewModel.loadFile(at: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Check if provider has a file URL
        guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard error == nil,
                  let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                Task { @MainActor in
                    viewModel.errorMessage = "Could not read the dropped file"
                }
                return
            }

            // Validate file type
            guard DocumentViewModel.isMarkdownFile(url) else {
                Task { @MainActor in
                    viewModel.errorMessage = "Only markdown files (.md, .markdown) are supported"
                }
                return
            }

            Task {
                await viewModel.loadFile(at: url)
            }
        }

        return true
    }
}

#Preview {
    ContentView()
}
