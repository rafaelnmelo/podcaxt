import SwiftUI

@main
struct podcaxtApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            tabView
                .environmentObject(playerViewModel)
                .environmentObject(coordinator)
        }
    }
}

private extension podcaxtApp {
    var tabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            RSSInputView()
                .safeAreaInset(edge: .bottom) { miniPlayer }
                .tag(AppCoordinator.Tab.search)
                .tabItem { Label(AppCoordinator.Tab.search.label, systemImage: AppCoordinator.Tab.search.icon) }
            NavigationStack {
                SettingsView()
            }
            .safeAreaInset(edge: .bottom) { miniPlayer }
            .tag(AppCoordinator.Tab.settings)
            .tabItem { Label(AppCoordinator.Tab.settings.label, systemImage: AppCoordinator.Tab.settings.icon) }
        }
    }

    @ViewBuilder
    var miniPlayer: some View {
        if playerViewModel.currentEpisode != nil {
            MiniPlayerView()
                .environmentObject(playerViewModel)
        }
    }
}
