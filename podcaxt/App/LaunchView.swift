import SwiftUI

struct LaunchView: View {
    @State private var ready = false

    var body: some View {
        if ready {
            ContentView()
                .transition(.opacity)
        } else {
            splash
                .task {
                    try? await Task.sleep(for: .milliseconds(600))
                    withAnimation(.easeInOut(duration: 0.4)) { ready = true }
                }
        }
    }

    private var splash: some View {
        ZStack {
            Color(hex: 0x007AFF).ignoresSafeArea()
            Image("Launch")
                .resizable()
                .scaledToFit()
                .frame(width: 240)
                .clipShape(RoundedRectangle(cornerRadius: 26))
        }
        .transition(.opacity)
    }
}
