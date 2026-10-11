# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TagForge is an iOS/iPadOS app (iOS 18.0+, portrait only) for generating hashtags from word combinations. Users build word sets, configure formatting options, and generate tags with optional combination permutations.

## Build & Project Setup

This project uses **Tuist** for project generation. Never edit `.xcodeproj` files directly.

```bash
# Regenerate Xcode projects after modifying Project.swift or Tuist helpers
tuist generate

# Install dependencies and generate
tuist install && tuist generate
```

Open `App.xcworkspace` in Xcode to build and run.

## Architecture

**MVVM** with SwiftData persistence and iCloud sync via CloudKit.

### Module Structure

```
Projects/
  App/              # Main app target (SwiftUI, iOS 18+)
  DynamicThirdParty/# Dynamic framework wrapper (Firebase suite)
Tuist/
  Package.swift               # SwiftPM dependencies (Firebase) + PackageSettings
  ProjectDescriptionHelpers/  # Shared Tuist helpers
```

### Key Files

| File | Role |
|------|------|
| `Projects/App/Sources/TagForgeApp.swift` | App entry; handles splash/sync state |
| `Projects/App/Sources/ContentView.swift` | Root view with all inline sub-views as private functions |
| `Projects/App/Sources/ViewModels/MainViewModel.swift` | `@MainActor ObservableObject`; all business logic |
| `Projects/App/Sources/Managers/WordSetManager.swift` | SwiftData + CloudKit persistence layer (singleton) |
| `Projects/App/Sources/Models/WordSetModel.swift` | `@Model` — word set with cascade delete to words |
| `Projects/App/Sources/Models/WordModel.swift` | `@Model` — individual word with `order` for display sorting |

### Data Flow

`WordSetManager` (SwiftData + CloudKit private DB) → `MainViewModel` (publishes state) → SwiftUI views

Remote sync is detected via `NSPersistentStoreRemoteChange` notification, debounced 2s, then reloads word sets.

### Tag Generation Logic (`MainViewModel.generateTags`)

1. Apply `replaceSpaces` (spaces → `_`) to each word
2. If `generateCombinations`: generate all permutations of length 2…n using `Array.combinations(ofLength:)` from `Extensions/Array+.swift`
3. If `attachSharp`: prefix each tag with `#`
4. Join with `, `

## Tuist Conventions

- `String.projects.*` constants in `Tuist/ProjectDescriptionHelpers/Constants.swift` are used as project/target names
- `Project.makeModule(...)` in `Project+Templates.swift` is the factory for the DynamicThirdParty module target
- SwiftPM dependencies live in `Tuist/Package.swift` (not per-project `packages:`); targets reference them with `.external(name:)`. Run `tuist install` after changing it; `Tuist/Package.resolved` is the lockfile
- Bundle ID base: `com.toyboy2.tagforge`
- Xcode compatibility: 16.4, Swift 5.7

## Code Style

- Avoid force-unwrap (`!`); use optional binding
- No business logic in views — delegate to `MainViewModel`
- Use `os_log` in production code, not `print`
- Use `Localizable.strings` for user-facing strings rather than hardcoded literals
- `@MainActor` on ViewModel and Manager classes (SwiftData requirement)
