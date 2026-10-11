import SwiftUI
import FirebaseCore
import os

private let appLogger = Logger(subsystem: "com.toyboy2.tagforge", category: "TagForgeApp")

@main
struct TagForgeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isSyncing = true
    @State private var syncMessage = ""

    init() {
        Self.configureFirebase()
    }

    /// GoogleService-Info.plist is not tracked in git; skip configuration when it is absent
    /// so local builds and unit tests keep working without Firebase credentials.
    private static func configureFirebase() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            appLogger.warning("GoogleService-Info.plist not found in main bundle; Firebase is not configured")
            return
        }
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(isSyncing: $isSyncing, syncMessage: $syncMessage)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .opacity((isSyncing) ? 0 : 1)

                if isSyncing {
                    SplashScreenView(syncMessage: syncMessage)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
} 