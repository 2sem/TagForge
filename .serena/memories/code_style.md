# Code Style & Conventions

- No force-unwrap (!); use optional binding
- No business logic in views — delegate to MainViewModel
- Use os_log not print (production)
- Localizable.strings for user-facing strings (not hardcoded literals)
- @MainActor on ViewModel and Manager classes
- Bundle ID base: com.toyboy2.tagforge
- Swift 5.7, Xcode 16.4 compatible
- Avoid editing .xcodeproj directly (use Tuist)
- String.projects.* constants for project/target names in Constants.swift
- Project.makeModule(...) factory in Project+Templates.swift
