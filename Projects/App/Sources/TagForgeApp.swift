import SwiftUI

@main
struct TagForgeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isSyncing = true

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE") {
            ScreenshotContainerView()
        } else {
            mainContent
        }
        #else
        mainContent
        #endif
    }

    private var mainContent: some View {
        ZStack {
            ContentView(isSyncing: $isSyncing)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .opacity(isSyncing ? 0 : 1)

            if isSyncing {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
} 