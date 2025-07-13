import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var backgroundGradient = false
    @State private var rotationAngle: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.15, green: 0.25, blue: 0.5),
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ]),
                startPoint: backgroundGradient ? .topLeading : .bottomTrailing,
                endPoint: backgroundGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: backgroundGradient)
            
            VStack(spacing: 40) {
                // 로고 컨테이너
                ZStack {
                    // 글로우 효과
                    Image("LaunchLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale)
                    
                    // 메인 로고
                    Image("LaunchLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(rotationAngle))
                        .shadow(color: .white.opacity(0.5), radius: 30, x: 0, y: 0)
                }
                
                VStack(spacing: 15) {
                    // 앱 이름
                    Text("TagForge")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    
                    // 부제목
                    Text("Try generating tags")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 배경 애니메이션 시작
        backgroundGradient = true
        
        // 로고 애니메이션
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 글로우 효과 애니메이션
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.3
            pulseScale = 1.1
        }
        
        // 회전 애니메이션
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360.0
        }
        
        // 텍스트 애니메이션 (지연 후 시작)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.2)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 