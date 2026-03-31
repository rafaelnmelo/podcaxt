import SwiftUI

struct LaunchView: View {
    @EnvironmentObject private var rssInputViewModel: RSSInputViewModel
    @State private var ready = false

    var body: some View {
        if ready {
            ContentView()
                .transition(.opacity)
        } else {
            splash
                .task {
                    rssInputViewModel.loadHistory()
                    try? await Task.sleep(for: .milliseconds(600))
                    withAnimation(.easeInOut(duration: 0.4)) { ready = true }
                }
        }
    }

    private var splash: some View {
        ZStack {
            Color(hex: 0xFFC300).ignoresSafeArea()
            Image("Launch")
                .resizable()
                .scaledToFit()
                .frame(width: 240)
                .clipShape(RoundedRectangle(cornerRadius: 26))
        }
        .transition(.opacity)
    }
}
