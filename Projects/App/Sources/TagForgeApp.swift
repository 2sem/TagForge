import SwiftUI

@main
struct TagForgeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isSyncing = true
    @State private var syncMessage = ""

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