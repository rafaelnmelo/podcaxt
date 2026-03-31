import SwiftUI

class AppCoordinator: ObservableObject {
    enum Tab: CaseIterable {
        case search, settings

        var label: String {
            switch self {
            case .search: Strings.Tab.search
            case .settings: Strings.Tab.settings
            }
        }

        var icon: String {
            switch self {
            case .search: SystemImage.magnifyingglass
            case .settings: SystemImage.gearshape
            }
        }
    }

    @Published var selectedTab: Tab = .search
}
