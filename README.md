# SwiftMarkdown

A native macOS markdown preview application with Quick Look integration and syntax highlighting for 35+ programming languages.

## Features

- **Native macOS App** - Built with Swift and SwiftUI for a seamless Mac experience
- **Quick Look Integration** - Press spacebar in Finder to preview markdown files
- **Syntax Highlighting** - 35+ languages via tree-sitter grammars
- **Light/Dark Mode** - Automatic theme switching with VS Code-inspired colors
- **On-Demand Grammars** - Languages downloaded on first use and cached permanently
- **Homebrew Grammar Support** - Install grammars via Homebrew for instant offline use
- **Graceful Degradation** - Unknown languages render as plain text without errors

## Installation

### Homebrew (Recommended)

```bash
brew install --cask open-cli-collective/tap/swiftmarkdown
```

> **Note:** This installs from our third-party tap, not the official Homebrew cask repository.

### Direct Download

Download the latest DMG from the [Releases page](https://github.com/open-cli-collective/SwiftMarkdown/releases).

## System Requirements

- macOS 13.0+ (Ventura)
- Apple Silicon or Intel

## Quick Start

1. Install SwiftMarkdown via Homebrew or DMG
2. Open any `.md` file with SwiftMarkdown
3. Or press **spacebar** on a markdown file in Finder for Quick Look preview

## Configuration

### Language Settings

Open **SwiftMarkdown > Settings > Languages** to manage syntax highlighting grammars:

- View all 35+ supported languages
- See grammar sources: "(via Homebrew)" or "(downloaded)"
- Download individual languages or popular bundles
- Clear the grammar cache if needed

### Grammar Cache

Downloaded grammars are stored permanently at:

```
~/Library/Application Support/SwiftMarkdown/Grammars/
```

### Homebrew Grammars (Optional)

For instant offline access to all grammars, install via Homebrew:

```bash
brew install open-cli-collective/tap/swiftmarkdown-grammars
```

Grammars installed via Homebrew are preferred over cached versions.

## Quick Look Integration

SwiftMarkdown includes a Quick Look extension for previewing markdown files directly in Finder:

1. Select any `.md` file in Finder
2. Press **spacebar** to open Quick Look
3. See rendered markdown with syntax highlighting

Supported file types:
- `net.daringfireball.markdown`
- `public.plain-text`

## Supported Languages

SwiftMarkdown supports syntax highlighting for these languages:

| Language | Language | Language | Language |
|----------|----------|----------|----------|
| Bash | C | C++ | C# |
| CSS | Dockerfile | Go | GraphQL |
| HTML | Java | JavaScript | JSON |
| Kotlin | Lua | Makefile | Markdown |
| Objective-C | Perl | PHP | Python |
| Ruby | Rust | Scala | SQL |
| Swift | TOML | TypeScript | XML |
| YAML | Zig | ... and more | |

## Development

### Prerequisites

- macOS 13.0+
- Xcode 15+
- Swift 5.9+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SwiftLint](https://github.com/realm/SwiftLint)

### Build

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build
xcodebuild build -scheme SwiftMarkdown -destination 'platform=macOS,arch=arm64'
```

### Test

```bash
xcodebuild test -scheme SwiftMarkdown -destination 'platform=macOS,arch=arm64'
```

### Lint

```bash
swiftlint lint --strict
```

### Project Structure

```
SwiftMarkdown/
├── SwiftMarkdown/           # Main macOS app (SwiftUI)
├── SwiftMarkdownCore/       # Shared framework (parsing, rendering)
├── SwiftMarkdownQuickLook/  # Quick Look extension
└── SwiftMarkdownTests/      # Unit tests
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes using [conventional commits](https://www.conventionalcommits.org/)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

### Commit Convention

- `feat:` - New features (triggers release)
- `fix:` - Bug fixes (triggers release)
- `docs:` - Documentation only
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Maintenance tasks

## License

MIT License - see [LICENSE](LICENSE) for details.
