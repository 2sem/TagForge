import SwiftUI

@main
struct TagForgeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .opacity(showingSplash ? 0 : 1)
                
                if showingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // 3초 후 스플래시 스크린 숨기기
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
            }
        }
    }
} 