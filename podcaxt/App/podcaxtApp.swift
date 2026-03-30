import SwiftUI

@main
struct podcaxtApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()

    var body: some Scene {
        WindowGroup {
            RSSInputView()
                .environmentObject(playerViewModel)
                .safeAreaInset(edge: .bottom) {
                    if playerViewModel.currentEpisode != nil {
                        MiniPlayerView()
                            .environmentObject(playerViewModel)
                    }
                }
        }
    }
}
