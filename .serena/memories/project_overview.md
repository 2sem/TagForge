# TagForge Project Overview

## Purpose
iOS/iPadOS app (iOS 17.0+, portrait only) for generating hashtags from word combinations. Users build word sets, configure formatting options (replace spaces, add #, generate combos), and copy/share the result.

## Tech Stack
- SwiftUI (iOS 17+)
- SwiftData + CloudKit (iCloud sync via private DB)
- MVVM architecture
- Tuist for project generation (never edit .xcodeproj directly)
- Alamofire (ThirdParty static framework)
- Firebase suite (DynamicThirdParty dynamic framework)

## Module Structure
```
Projects/
  App/              # Main app target
  ThirdParty/       # Static framework (Alamofire)
  DynamicThirdParty/# Dynamic framework (Firebase)
Tuist/
  ProjectDescriptionHelpers/
```

## Key Files
- TagForgeApp.swift — entry point; handles splash/sync, isDarkMode AppStorage
- ContentView.swift — root view with all sub-views as private functions
- MainViewModel.swift — @MainActor ObservableObject; all business logic
- WordSetManager.swift — SwiftData + CloudKit persistence (singleton)
- WordSetModel.swift — @Model word set with cascade delete
- WordModel.swift — @Model individual word with order
- WordSetPickerView.swift — sheet for selecting/deleting word sets
- SplashScreenView.swift — animated logo while CloudKit syncs (min 2s)
- FlowLayout.swift — custom Layout for chip wrapping

## Data Flow
WordSetManager (SwiftData+CloudKit) → MainViewModel (@Published) → SwiftUI views

## Tag Generation Logic
1. replaceSpaces: spaces → _
2. generateCombinations: all combos of length 2…n (joined, no separator)
3. attachSharp: prefix # to each tag
4. join with ", "
