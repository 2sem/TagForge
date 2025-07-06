import SwiftUI

@main
struct TagForgeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isSyncing = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(isSyncing: $isSyncing)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .opacity((isSyncing) ? 0 : 1)

                if isSyncing {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
} 