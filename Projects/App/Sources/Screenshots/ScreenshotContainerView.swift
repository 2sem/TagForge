#if DEBUG
import SwiftUI

struct ScreenshotContainerView: View {
    var body: some View {
        TabView {
            Screenshot1()
                .tabItem { Label("1", systemImage: "1.circle") }

            Screenshot2()
                .tabItem { Label("2", systemImage: "2.circle") }

            Screenshot3()
                .tabItem { Label("3", systemImage: "3.circle") }

            Screenshot4()
                .tabItem { Label("4", systemImage: "4.circle") }

            Screenshot5()
                .tabItem { Label("5", systemImage: "5.circle") }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ScreenshotContainerView()
}
#endif
