import SwiftUI

struct SplashView: View {
    @State private var logoScale = 0.8
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.surfacePrimary.ignoresSafeArea()

            // Subtle glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.brand.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)

            VStack(spacing: 28) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.brand.opacity(0.3), radius: 20, y: 8)
                    .scaleEffect(logoScale)

                ProgressView()
                    .tint(.brand)
            }
            .opacity(opacity)
        }
        .task {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                opacity = 1.0
            }
        }
    }
}
