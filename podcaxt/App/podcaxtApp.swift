import SwiftUI

@main
struct PodcaxtApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var rssInputViewModel = RSSInputViewModel()

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(playerViewModel)
                .environmentObject(coordinator)
                .environmentObject(rssInputViewModel)
        }
    }
}
