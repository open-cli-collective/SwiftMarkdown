# CLAUDE.md

This file provides guidance for working with the SwiftMarkdown project.

## Project Overview

SwiftMarkdown is a macOS markdown preview application with Quick Look integration.

## Build Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build
xcodebuild build -scheme SwiftMarkdown -destination 'platform=macOS,arch=arm64'

# Test
xcodebuild test -scheme SwiftMarkdown -destination 'platform=macOS,arch=arm64'

# Lint
swiftlint lint --strict
```

## Project Structure

| Directory | Description |
|-----------|-------------|
| `SwiftMarkdown/` | Main macOS app target (SwiftUI) |
| `SwiftMarkdownCore/` | Framework with shared markdown parsing logic |
| `SwiftMarkdownTests/` | Unit tests for core framework |
| `SwiftMarkdownQuickLook/` | Quick Look extension for spacebar preview |

## Architecture

- **XcodeGen**: Project is defined in `project.yml`, run `xcodegen generate` after changes
- **Targets**: App embeds Core framework; Quick Look extension also links Core
- **Deployment**: macOS 13.0+ (Ventura), Swift 5.9+
- **Settings**: Stored in `~/.config/swiftmarkdown/settings.json`, uses `FileSystemProtocol` for testability

## CI/CD

Follows the same patterns as sibling Go CLI repos:

- **ci.yml**: Build, test, lint on PRs and pushes to main
- **auto-release.yml**: Creates tags on `feat:`/`fix:` commits using `v{version.txt}.{run_number}`
- **release.yml**: Builds DMG, uploads to GitHub releases, updates homebrew-tap cask

## Versioning

- Base version in `version.txt` (e.g., `0.1`)
- Full version: `v{base}.{github_run_number}` (e.g., `v0.1.42`)
- Only `feat:` and `fix:` commits trigger releases

## Commit Convention

Use conventional commits:
- `feat:` - New features (triggers release)
- `fix:` - Bug fixes (triggers release)
- `docs:` - Documentation only
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `test:` - Test changes

## Distribution

- **Homebrew**: `brew install --cask open-cli-collective/tap/swiftmarkdown`
- **DMG**: Direct download from GitHub releases
- **Signing**: Currently ad-hoc (xattr quarantine removal via Homebrew postflight)

## Commenting Guidelines

Comments should explain **why**, not what or how:

- **Don't comment the obvious**: If code is self-explanatory, no comment needed
- **Explain intent**: Why was this approach chosen? What trade-off was made?
- **Non-obvious behavior**: If the "how" is unusual or surprising, explain it
- **Delete stale comments**: Outdated comments are worse than no comments

Bad: `// Create a parser` before `let parser = Parser()`
Good: `// Use Task.detached to avoid blocking the UI thread`
