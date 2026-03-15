# TagForge

Generate hashtags from word combinations — fast, flexible, and synced across your devices.

## Overview

TagForge lets you build word sets and generate all possible hashtag combinations from them. Perfect for content creators who want to maximize hashtag variety without repetitive manual work.

- Build word sets with your keywords
- Generate every combination automatically
- Copy or share the result in one tap
- Syncs across all your devices via iCloud

## Requirements

- iOS 18.0+
- Xcode 26.1.1+
- [Tuist](https://tuist.io) 4.153.1 (managed via [mise](https://mise.jdx.dev))

## Getting Started

```bash
# Install mise (if not already installed)
curl https://mise.run | sh

# Install Tuist and dependencies
mise install
tuist install

# Generate Xcode project
tuist generate --no-open
```

Open `App.xcworkspace` in Xcode to build and run.

## Architecture

**MVVM** with SwiftData persistence and iCloud sync via CloudKit.

```
Projects/
  App/                    # Main app target (SwiftUI, iOS 17+)
  ThirdParty/             # Static framework wrapper (Alamofire)
  DynamicThirdParty/      # Dynamic framework wrapper (Firebase suite)
Tuist/
  ProjectDescriptionHelpers/  # Shared Tuist helpers
```

| File | Role |
|------|------|
| `TagForgeApp.swift` | App entry; handles splash/sync state |
| `ContentView.swift` | Root view |
| `MainViewModel.swift` | All business logic (`@MainActor ObservableObject`) |
| `WordSetManager.swift` | SwiftData + CloudKit persistence (singleton) |
| `WordSetModel.swift` | Word set model with cascade delete |
| `WordModel.swift` | Individual word with display order |

## Deploy

The project uses [Fastlane](https://fastlane.tools) and GitHub Actions for CI/CD.

Trigger a deploy manually from **Actions → DEPLOY IOS**:

| Input | Description |
|-------|-------------|
| `심사제출` | `true` → submit for App Store review, `false` → TestFlight only |
| `TestFlight 변경사항` | Release notes for TestFlight builds |

### Required Secrets & Variables

| Name | Type |
|------|------|
| `PRODUCT_NAME` | Variable |
| `PACKAGE_NAME` | Secret |
| `IOS_CERT_P12_DATA` | Secret |
| `IOS_CERT_P12_PWD` | Secret |
| `IOS_PROFILE_DATA` | Secret |
| `IOS_API_KEY` | Secret |
| `APPLE_TEAM_ID` | Secret |
| `IOS_KEYCHAIN` | Secret |
| `IOS_KEYCHAIN_PWD` | Secret |

## License

Copyright © 2025 toyboy2. All rights reserved.
