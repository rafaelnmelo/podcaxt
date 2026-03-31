import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            searchTab
            settingsTab
        }
    }

    private var searchTab: some View {
        RSSInputView()
            .safeAreaInset(edge: .bottom) { miniPlayer }
            .tag(AppCoordinator.Tab.search)
            .tabItem { Label(AppCoordinator.Tab.search.label, systemImage: AppCoordinator.Tab.search.icon) }
    }

    private var settingsTab: some View {
        NavigationStack {
            SettingsView()
        }
        .safeAreaInset(edge: .bottom) { miniPlayer }
        .tag(AppCoordinator.Tab.settings)
        .tabItem { Label(AppCoordinator.Tab.settings.label, systemImage: AppCoordinator.Tab.settings.icon) }
    }

    @ViewBuilder
    private var miniPlayer: some View {
        if playerViewModel.currentEpisode != nil {
            MiniPlayerView()
        }
    }
}
